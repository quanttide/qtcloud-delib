package gorm

import (
	"encoding/json"

	"gorm.io/gorm"

	"github.com/quanttide/qtcloud-delib-provider/internal/topic"
)

// TopicRepo 议题 GORM 实现。
// SeconderIDs/Votes 以 JSON 列存储（SQLite/Postgres 通用）。
type TopicRepo struct{}

func NewTopicRepo() *TopicRepo { return &TopicRepo{} }

// 直接使用 topic.Topic（含 JSON 附加列字段）
func (r *TopicRepo) List(db *gorm.DB) ([]topic.Topic, error) {
	var rows []topic.Topic
	if err := db.Model(&topic.Topic{}).Order("created_at desc").Find(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]topic.Topic, 0, len(rows))
	for i := range rows {
		out = append(out, hydrate(rows[i]))
	}
	return out, nil
}

func (r *TopicRepo) Get(db *gorm.DB, id string) (*topic.Topic, error) {
	var row topic.Topic
	if err := db.Model(&topic.Topic{}).Where("id = ?", id).First(&row).Error; err != nil {
		return nil, err
	}
	t := hydrate(row)
	return &t, nil
}

func (r *TopicRepo) GetByName(db *gorm.DB, name string) (*topic.Topic, error) {
	var row topic.Topic
	if err := db.Model(&topic.Topic{}).Where("name = ?", name).First(&row).Error; err != nil {
		return nil, err
	}
	t := hydrate(row)
	return &t, nil
}

func (r *TopicRepo) Create(db *gorm.DB, t *topic.Topic) error {
	row := dehydrate(*t)
	return db.Create(&row).Error
}

// UpdateByName 按 name 更新内容字段（seed 幂等用；不动 status/附议/票数）。
func (r *TopicRepo) UpdateByName(db *gorm.DB, name string, t *topic.Topic) error {
	return db.Model(&topic.Topic{}).Where("name = ?", name).Updates(map[string]any{
		"title": t.Title, "content": t.Content, "category": t.Category,
		"ledger_no": t.LedgerNo, "source": t.Source, "updated_at": t.UpdatedAt,
	}).Error
}

func (r *TopicRepo) Update(db *gorm.DB, t *topic.Topic) error {
	row := dehydrate(*t)
	return db.Model(&topic.Topic{}).Where("id = ?", t.ID).Updates(map[string]any{
		"name": row.Name, "title": row.Title, "content": row.Content,
		"category": row.Category, "ledger_no": row.LedgerNo, "source": row.Source,
		"status": row.Status, "proposer_id": row.ProposerID,
		"seconder_ids_json": row.SeconderIDsJSON, "votes_json": row.VotesJSON,
		"resolution_id": row.ResolutionID, "resolved_at": row.ResolvedAt,
		"updated_at": row.UpdatedAt,
	}).Error
}

func hydrate(row topic.Topic) topic.Topic {
	json.Unmarshal([]byte(row.SeconderIDsJSON), &row.SeconderIDs)
	json.Unmarshal([]byte(row.VotesJSON), &row.Votes)
	if row.VotesJSON == "" {
		row.Votes = topic.VoteResult{}
	}
	row.SeconderIDsJSON = ""
	row.VotesJSON = ""
	return row
}

func dehydrate(t topic.Topic) topic.Topic {
	sec, _ := json.Marshal(t.SeconderIDs)
	votes, _ := json.Marshal(t.Votes)
	if sec == nil {
		sec = []byte("[]")
	}
	if votes == nil {
		votes = []byte("{}")
	}
	t.SeconderIDsJSON = string(sec)
	t.VotesJSON = string(votes)
	return t
}
