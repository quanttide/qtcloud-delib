package resolution

import (
	"context"
	"errors"
	"strings"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ErrInvalidInput 决议入参不合法（name/title 必填）。
var ErrInvalidInput = errors.New("resolution: invalid input")

// ErrDuplicateName name（slug）已存在，唯一索引冲突。
var ErrDuplicateName = errors.New("resolution: duplicate name")

// Service 决议服务：业务规则与用例编排。
type Service struct {
	db   *gorm.DB
	repo Repository
}

// NewService 创建决议服务。
func NewService(db *gorm.DB, repo Repository) *Service {
	return &Service{db: db, repo: repo}
}

// List 决议清单（按 name 排序）。
func (s *Service) List(ctx context.Context) ([]Resolution, error) {
	return s.repo.List(s.db)
}

// Create 创建决议：ID 为空时生成 UUID；name/title 必填。
func (s *Service) Create(ctx context.Context, r *Resolution) (*Resolution, error) {
	if r == nil {
		return nil, ErrInvalidInput
	}
	r.Name = strings.TrimSpace(r.Name)
	r.Title = strings.TrimSpace(r.Title)
	if r.Name == "" || r.Title == "" {
		return nil, ErrInvalidInput
	}
	if r.ID == "" {
		r.ID = uuid.NewString()
	}
	if err := s.repo.Create(s.db, r); err != nil {
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			return nil, ErrDuplicateName
		}
		return nil, err
	}
	return r, nil
}
