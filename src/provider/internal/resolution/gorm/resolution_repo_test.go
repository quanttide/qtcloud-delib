package gorm_test

import (
	"errors"
	"testing"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"github.com/quanttide/qtcloud-delib-provider/internal/resolution"
	resolutiongorm "github.com/quanttide/qtcloud-delib-provider/internal/resolution/gorm"
)

func setupRepoDB(t *testing.T) *gorm.DB {
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

func TestResolutionRepo(t *testing.T) {
	db := setupRepoDB(t)
	repo := resolutiongorm.NewResolutionRepo()
	res := &resolution.Resolution{
		ID: "5914902c-1d03-496d-8f56-d3f627c17caf", Name: "weekly-vote",
		Title: "周会实行记名表决制", Content: "重大事项记名表决。", Category: "治理",
	}

	if err := repo.Create(db, res); err != nil {
		t.Fatalf("create: %v", err)
	}

	got, err := repo.Get(db, res.ID)
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	if got.Name != res.Name {
		t.Errorf("Name = %q, want %q", got.Name, res.Name)
	}

	byName, err := repo.GetByName(db, "weekly-vote")
	if err != nil {
		t.Fatalf("get by name: %v", err)
	}
	if byName.ID != res.ID {
		t.Errorf("ID = %q, want %q", byName.ID, res.ID)
	}

	if _, err := repo.Get(db, "missing"); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Errorf("Get(missing) = %v, want gorm.ErrRecordNotFound", err)
	}
	if _, err := repo.GetByName(db, "missing"); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Errorf("GetByName(missing) = %v, want gorm.ErrRecordNotFound", err)
	}

	items, err := repo.List(db)
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(items) != 1 || items[0].Name != "weekly-vote" {
		t.Fatalf("items = %+v, want 1 weekly-vote", items)
	}
}
