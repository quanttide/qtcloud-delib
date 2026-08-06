package resolution_test

import (
	"context"
	"errors"
	"testing"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"github.com/quanttide/qtcloud-delib-provider/internal/resolution"
	resolutiongorm "github.com/quanttide/qtcloud-delib-provider/internal/resolution/gorm"
)

// setupDB 打开内存 SQLite 并迁移模型（对齐 pay service_test.go 模式）。
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

func TestServiceCreateAndList(t *testing.T) {
	db := setupDB(t)
	svc := resolution.NewService(db, resolutiongorm.NewResolutionRepo())
	ctx := context.Background()

	created, err := svc.Create(ctx, &resolution.Resolution{
		Name: "weekly-vote", Title: "周会实行记名表决制",
		Content: "重大事项记名表决。", Category: "治理",
	})
	if err != nil {
		t.Fatalf("create: %v", err)
	}
	if created.ID == "" {
		t.Error("ID should be generated when empty")
	}

	items, err := svc.List(ctx)
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(items) != 1 || items[0].Name != "weekly-vote" {
		t.Fatalf("items = %+v, want 1 weekly-vote", items)
	}
}

func TestServiceCreateKeepsProvidedID(t *testing.T) {
	db := setupDB(t)
	svc := resolution.NewService(db, resolutiongorm.NewResolutionRepo())

	created, err := svc.Create(context.Background(), &resolution.Resolution{
		ID: "5914902c-1d03-496d-8f56-d3f627c17caf", Name: "data-contract", Title: "数据契约",
	})
	if err != nil {
		t.Fatalf("create: %v", err)
	}
	if created.ID != "5914902c-1d03-496d-8f56-d3f627c17caf" {
		t.Errorf("ID = %q, want provided UUID", created.ID)
	}
}

func TestServiceCreateInvalid(t *testing.T) {
	db := setupDB(t)
	svc := resolution.NewService(db, resolutiongorm.NewResolutionRepo())
	ctx := context.Background()

	cases := []*resolution.Resolution{
		nil,
		{Title: "缺 name"},
		{Name: "no-title"},
		{Name: "  ", Title: "只有空格"},
	}
	for _, c := range cases {
		if _, err := svc.Create(ctx, c); err == nil {
			t.Errorf("Create(%+v): want error", c)
		}
	}
}

func TestServiceCreateDuplicateName(t *testing.T) {
	db := setupDB(t)
	svc := resolution.NewService(db, resolutiongorm.NewResolutionRepo())
	ctx := context.Background()

	if _, err := svc.Create(ctx, &resolution.Resolution{Name: "data-contract", Title: "数据契约"}); err != nil {
		t.Fatalf("first create: %v", err)
	}
	if _, err := svc.Create(ctx, &resolution.Resolution{Name: "data-contract", Title: "重复"}); !errors.Is(err, resolution.ErrDuplicateName) {
		t.Fatalf("second create = %v, want ErrDuplicateName", err)
	}
}
