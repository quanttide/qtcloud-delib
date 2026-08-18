// Package topic 提供议题领域：五流程（动议→附议→辩论→表决→决议）。
package topic

import (
	"time"

	"gorm.io/gorm"
)

// 议题状态（罗伯特议事规则五流程）。
const (
	StatusProposed = "proposed" // 动议：已提出，待附议
	StatusSeconded = "seconded" // 附议：已获附议，可辩论
	StatusDebated  = "debated"  // 辩论：辩论中，可表决
	StatusVoted    = "voted"    // 表决：表决完成待归档
	StatusResolved = "resolved" // 决议：表决通过，归档为决议
	StatusRejected = "rejected" // 否决：表决未通过，归档关闭
)

// VoteResult 表决结果。
type VoteResult struct {
	For     int `json:"for"`
	Against int `json:"against"`
	Abstain int `json:"abstain"`
}

// Topic 议题：从动议到决议的完整生命周期。
type Topic struct {
	ID           string      `gorm:"primaryKey;size:36" json:"id"`
	Name         string      `gorm:"size:64;uniqueIndex" json:"name"` // slug（唯一）
	Title        string      `gorm:"size:255" json:"title"`
	Content      string      `gorm:"type:text" json:"content"`
	Category     string      `gorm:"size:32" json:"category"`
	LedgerNo     string      `gorm:"size:16;index" json:"ledgerNo,omitempty"` // 台账编号（M-XX，议事档案导入）
	Source       string      `gorm:"size:64" json:"source,omitempty"`         // 来源（第N周-提案N）
	Status       string      `gorm:"size:16" json:"status"`
	ProposerID   string      `gorm:"size:64" json:"proposerId"`   // 动议人（账号用户 ID）
	SeconderIDs  []string    `gorm:"-" json:"seconderIds"`        // 附议人（JSON 列存储）
	Votes        VoteResult  `gorm:"-" json:"votes"`               // 表决结果（JSON 列存储）
	SeconderIDsJSON string   `gorm:"column:seconder_ids_json;type:text" json:"-"` // JSON 列（仓库层使用）
	VotesJSON       string   `gorm:"column:votes_json;type:text" json:"-"`        // JSON 列（仓库层使用）
	ResolutionID string      `gorm:"size:36" json:"resolutionId,omitempty"` // 通过后关联决议
	CreatedAt    time.Time   `json:"created_at"`
	UpdatedAt    time.Time   `json:"updated_at"`
	ResolvedAt   *time.Time  `json:"resolved_at,omitempty"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName 自定义表名（附议人/表决存 JSON 列）。
func (Topic) TableName() string { return "topics" }
