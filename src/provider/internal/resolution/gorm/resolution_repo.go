// Package gorm 提供决议仓库的 GORM 实现（开发 SQLite / 生产 PostgreSQL 方言切换）。
package gorm

import (
	"gorm.io/gorm"

	"github.com/quanttide/qtcloud-delib-provider/internal/resolution"
)

// ResolutionRepo 决议 GORM 仓库。
type ResolutionRepo struct{}

// NewResolutionRepo 创建决议 GORM 仓库。
func NewResolutionRepo() *ResolutionRepo {
	return &ResolutionRepo{}
}

func (r *ResolutionRepo) List(db *gorm.DB) ([]resolution.Resolution, error) {
	var res []resolution.Resolution
	if err := db.Order("name").Find(&res).Error; err != nil {
		return nil, err
	}
	return res, nil
}

func (r *ResolutionRepo) Get(db *gorm.DB, id string) (*resolution.Resolution, error) {
	var res resolution.Resolution
	if err := db.Where("id = ?", id).First(&res).Error; err != nil {
		return nil, err
	}
	return &res, nil
}

func (r *ResolutionRepo) GetByName(db *gorm.DB, name string) (*resolution.Resolution, error) {
	var res resolution.Resolution
	if err := db.Where("name = ?", name).First(&res).Error; err != nil {
		return nil, err
	}
	return &res, nil
}

func (r *ResolutionRepo) Create(db *gorm.DB, res *resolution.Resolution) error {
	return db.Create(res).Error
}

var _ resolution.Repository = (*ResolutionRepo)(nil)
