package store_test

import (
	"errors"
	"testing"

	"gorm.io/gorm"

	"github.com/quanttide/qtcloud-delib-provider/internal/resolution"
	"github.com/quanttide/qtcloud-delib-provider/internal/store"
)

// TestResolutionRepoMemory 内存仓库作为测试替身的可用性验证。
func TestResolutionRepoMemory(t *testing.T) {
	repo := store.NewResolutionRepo()
	res := &resolution.Resolution{
		ID: "5914902c-1d03-496d-8f56-d3f627c17caf", Name: "weekly-vote",
		Title: "周会实行记名表决制", Content: "重大事项记名表决。", Category: "治理",
	}
	var db *gorm.DB // 内存实现不依赖连接

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
	if _, err := repo.GetByName(db, "missing"); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Errorf("GetByName(missing) = %v, want gorm.ErrRecordNotFound", err)
	}
	items, err := repo.List(db)
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("len = %d, want 1", len(items))
	}
}
