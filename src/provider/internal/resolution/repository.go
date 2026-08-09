package resolution

import "gorm.io/gorm"

// Repository 决议存储接口。方法以 *gorm.DB 为首参，事务由调用方编排。
type Repository interface {
	// List 列出全部决议（按 name 排序）。
	List(db *gorm.DB) ([]Resolution, error)
	// Get 按 ID 查询决议；不存在返回 gorm.ErrRecordNotFound。
	Get(db *gorm.DB, id string) (*Resolution, error)
	// GetByName 按 name（slug）查询决议；不存在返回 gorm.ErrRecordNotFound。
	GetByName(db *gorm.DB, name string) (*Resolution, error)
	// Create 创建决议。
	Create(db *gorm.DB, r *Resolution) error
	// UpdateByName 按 name（slug）更新 title/content/category（ID 不变）。
	UpdateByName(db *gorm.DB, name string, r *Resolution) error
	// DeleteByName 按 name（slug）删除决议。
	DeleteByName(db *gorm.DB, name string) error
}
