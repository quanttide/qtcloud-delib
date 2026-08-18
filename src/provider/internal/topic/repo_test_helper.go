package topic

import "gorm.io/gorm"

// NewRepoForTest 测试用内存 repo（避免 gorm 包循环依赖——直接内联实现）。
func NewRepoForTest() Repository {
	return &memRepo{data: map[string]*Topic{}}
}

type memRepo struct {
	data map[string]*Topic
}

func (m *memRepo) List(_ *gorm.DB) ([]Topic, error) {
	out := make([]Topic, 0, len(m.data))
	for _, v := range m.data {
		out = append(out, *v)
	}
	return out, nil
}

func (m *memRepo) Get(_ *gorm.DB, id string) (*Topic, error) {
	v, ok := m.data[id]
	if !ok {
		return nil, gorm.ErrRecordNotFound
	}
	return v, nil
}

func (m *memRepo) GetByName(_ *gorm.DB, name string) (*Topic, error) {
	for _, v := range m.data {
		if v.Name == name {
			return v, nil
		}
	}
	return nil, gorm.ErrRecordNotFound
}

func (m *memRepo) Create(_ *gorm.DB, t *Topic) error {
	m.data[t.ID] = t
	return nil
}

func (m *memRepo) Update(_ *gorm.DB, t *Topic) error {
	m.data[t.ID] = t
	return nil
}
