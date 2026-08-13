package topic

import "gorm.io/gorm"

// Repository 议题存储接口。
type Repository interface {
	List(db *gorm.DB) ([]Topic, error)
	Get(db *gorm.DB, id string) (*Topic, error)
	Create(db *gorm.DB, t *Topic) error
	Update(db *gorm.DB, t *Topic) error
}
