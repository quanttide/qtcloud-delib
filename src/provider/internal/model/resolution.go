// Package model 提供议事领域模型。
package model

// Resolution 决议：决策记录。
//
// ID 为 UUID；Title 概括"决定了什么"，Content 展开决议陈述。
// Category 标注决议分类（如：治理、审计、档案、技术等）。
// 结构从实际议事档案标本中长出，不预设执行字段。
// Content 当前为纯文本，未来可扩展为结构化内容（如 Markdown、富文本、字段化陈述）。
type Resolution struct {
	ID       string `json:"id"`
	Title    string `json:"title"`
	Content  string `json:"content"`
	Category string `json:"category"`
}
