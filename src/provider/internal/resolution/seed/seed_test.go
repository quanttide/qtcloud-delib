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
		_, _ = fmt.Fprint(w, `[{"name":"data-contract.json"},{"name":"institutionalization.json"},{"name":"notes.txt"}]`)
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

	imported, err := seed.Import(context.Background(), db, apiURL, rawBase)
	if err != nil {
		t.Fatalf("import: %v", err)
	}
	if imported != 1 {
		t.Fatalf("imported = %d, want 1（notes.txt 非 JSON 标本应被过滤）", imported)
	}

	repo := resolutiongorm.NewResolutionRepo()
	got, err := repo.GetByName(db, "data-contract")
	if err != nil {
		t.Fatalf("get by name: %v", err)
	}
	if got.Title != "数据契约" || got.Category != "数据工程" {
		t.Fatalf("got = %+v", got)
	}

	// 幂等：重复导入不重复插入
	imported, err = seed.Import(context.Background(), db, apiURL, rawBase)
	if err != nil {
		t.Fatalf("re-import: %v", err)
	}
	if imported != 0 {
		t.Fatalf("re-imported = %d, want 0", imported)
	}
	items, err := repo.List(db)
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("len = %d, want 1", len(items))
	}
}
