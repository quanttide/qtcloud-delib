// Package store 提供决议仓库的内存实现（测试替身）。
package store

import (
	"gorm.io/gorm"

	"github.com/quanttide/qtcloud-delib-provider/internal/resolution"
)

// ResolutionRepo 决议仓库的内存实现，作为测试替身保留（生产走 internal/resolution/gorm）。
type ResolutionRepo struct {
	items map[string]resolution.Resolution // key: name（slug）
}

// NewResolutionRepo 创建决议内存仓库。
func NewResolutionRepo() *ResolutionRepo {
	return &ResolutionRepo{items: make(map[string]resolution.Resolution)}
}

func (r *ResolutionRepo) List(db *gorm.DB) ([]resolution.Resolution, error) {
	items := make([]resolution.Resolution, 0, len(r.items))
	for _, res := range r.items {
		items = append(items, res)
	}
	return items, nil
}

func (r *ResolutionRepo) Get(db *gorm.DB, id string) (*resolution.Resolution, error) {
	for _, res := range r.items {
		if res.ID == id {
			got := res
			return &got, nil
		}
	}
	return nil, gorm.ErrRecordNotFound
}

func (r *ResolutionRepo) GetByName(db *gorm.DB, name string) (*resolution.Resolution, error) {
	res, ok := r.items[name]
	if !ok {
		return nil, gorm.ErrRecordNotFound
	}
	got := res
	return &got, nil
}

func (r *ResolutionRepo) Create(db *gorm.DB, res *resolution.Resolution) error {
	r.items[res.Name] = *res
	return nil
}

func (r *ResolutionRepo) UpdateByName(db *gorm.DB, name string, res *resolution.Resolution) error {
	existing, ok := r.items[name]
	if !ok {
		return gorm.ErrRecordNotFound
	}
	existing.Title = res.Title
	existing.Content = res.Content
	existing.Category = res.Category
	r.items[name] = existing
	return nil
}

var _ resolution.Repository = (*ResolutionRepo)(nil)
