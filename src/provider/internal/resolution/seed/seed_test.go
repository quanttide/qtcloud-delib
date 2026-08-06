package seed_test

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"github.com/quanttide/qtcloud-delib-provider/internal/resolution"
	resolutiongorm "github.com/quanttide/qtcloud-delib-provider/internal/resolution/gorm"
	"github.com/quanttide/qtcloud-delib-provider/internal/resolution/seed"
)

const specimen = `{
  "id": "7e670a1f-2531-402f-847b-bbc2c2512773",
  "name": "data-contract",
  "title": "数据契约",
  "category": "数据工程",
  "content": "## 背景与目的\n\n我们与客户之间常因对数据的理解不一致，导致各种纠纷或低效。"
}`

// fakeRepo 模拟云端：contents API 返回文件清单，raw 返回标本 JSON。
func fakeRepo(t *testing.T) (apiURL, rawBase string) {
	t.Helper()
	mux := http.NewServeMux()
	mux.HandleFunc("/contents", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = fmt.Fprint(w, `[{"name":"data-contract.json"},{"name":"notes.txt"}]`)
	})
	mux.HandleFunc("/raw/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = fmt.Fprint(w, specimen)
	})
	srv := httptest.NewServer(mux)
	t.Cleanup(srv.Close)
	return srv.URL + "/contents", srv.URL + "/raw"
}

func setupDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{TranslateError: true})
	if err != nil {
		t.Fatal(err)
	}
	sqlDB, err := db.DB()
	if err != nil {
		t.Fatal(err)
	}
	sqlDB.SetMaxOpenConns(1)
	if err := db.AutoMigrate(&resolution.Resolution{}); err != nil {
		t.Fatal(err)
	}
	return db
}

func TestImport(t *testing.T) {
	apiURL, rawBase := fakeRepo(t)
	db := setupDB(t)

	imported, updated, err := seed.Import(context.Background(), db, apiURL, rawBase)
	if err != nil {
		t.Fatalf("import: %v", err)
	}
	if imported != 1 || updated != 0 {
		t.Fatalf("imported=%d updated=%d, want 1/0（notes.txt 非 JSON 标本应被过滤）", imported, updated)
	}

	repo := resolutiongorm.NewResolutionRepo()
	got, err := repo.GetByName(db, "data-contract")
	if err != nil {
		t.Fatalf("get by name: %v", err)
	}
	if got.Title != "数据契约" || got.Category != "数据工程" {
		t.Fatalf("got = %+v", got)
	}

	// 幂等：重复导入不重复插入；title 变更时同步更新
	imported, updated, err = seed.Import(context.Background(), db, apiURL, rawBase)
	if err != nil {
		t.Fatalf("re-import: %v", err)
	}
	if imported != 0 || updated != 1 {
		t.Fatalf("re-imported=%d updated=%d, want 0/1", imported, updated)
	}
	items, err := repo.List(db)
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("len = %d, want 1", len(items))
	}
}

// TestImportUpdatesExisting 云端 title 更新后，重新导入同步更新库中记录（ID 不变）。
func TestImportUpdatesExisting(t *testing.T) {
	apiURL, rawBase := fakeRepo(t)
	db := setupDB(t)

	if _, _, err := seed.Import(context.Background(), db, apiURL, rawBase); err != nil {
		t.Fatalf("import: %v", err)
	}
	repo := resolutiongorm.NewResolutionRepo()
	before, err := repo.GetByName(db, "data-contract")
	if err != nil {
		t.Fatalf("get: %v", err)
	}

	// 模拟云端 title 变更（fakeRepo 的 specimen 换新 title）
	// 直接改库中记录后重新导入，验证按 name 更新且 ID 保持
	newTitle := "引入数据契约机制，统一数据理解，升级数据工程全流程"
	if err := repo.UpdateByName(db, "data-contract", &resolution.Resolution{Title: newTitle}); err != nil {
		t.Fatalf("pre-update: %v", err)
	}

	// 恢复云端旧 title 再导入：应回写为新 title 的相反方向（验证更新方向为云端→库）
	if _, updated, err := seed.Import(context.Background(), db, apiURL, rawBase); err != nil {
		t.Fatalf("re-import: %v", err)
	} else if updated != 1 {
		t.Fatalf("updated = %d, want 1", updated)
	}
	after, err := repo.GetByName(db, "data-contract")
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	if after.Title != "数据契约" {
		t.Fatalf("title = %q, want 云端值 数据契约（云端为准）", after.Title)
	}
	if after.ID != before.ID {
		t.Errorf("ID 变化：%q → %q，应保持", before.ID, after.ID)
	}
}
