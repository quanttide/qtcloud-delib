// Package store 提供存储抽象（MVP 遗留，保留为测试替身；生产走 internal/resolution/gorm）。
package store

import "github.com/quanttide/qtcloud-delib-provider/internal/resolution"

// Storer 抽象存储后端，可对接任意存储实现（内存、文件、数据库等）。
type Storer interface {
	List(collection string) ([]byte, error)
	Create(collection string, data []byte) (string, error)
	Get(collection string, id string) ([]byte, error)
	Update(collection string, id string, data []byte) error
}

// MemoryStore 基于内存 map 的存储实现，用于开发调试。
type MemoryStore struct {
	data map[string]map[string][]byte
}

func NewMemoryStore() *MemoryStore {
	return &MemoryStore{data: make(map[string]map[string][]byte)}
}

func (s *MemoryStore) List(collection string) ([]byte, error) {
	return nil, nil
}

func (s *MemoryStore) Create(collection string, data []byte) (string, error) {
	return "", nil
}

func (s *MemoryStore) Get(collection string, id string) ([]byte, error) {
	return nil, nil
}

func (s *MemoryStore) Update(collection string, id string, data []byte) error {
	return nil
}

// ResolutionStore 决议集合辅助：以模型类型约束集合读写。
type ResolutionStore struct {
	Storer
}

func NewResolutionStore(st Storer) *ResolutionStore {
	return &ResolutionStore{Storer: st}
}

func (s *ResolutionStore) Create(r *resolution.Resolution) (string, error) {
	// TODO: 序列化后写入 Storer
	return r.ID, nil
}
