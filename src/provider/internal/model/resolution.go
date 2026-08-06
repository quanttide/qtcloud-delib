// Package model 提供议事领域模型。
package model

// Resolution 决议：决策记录。
//
// Title 概括"决定了什么"，Content 展开决议陈述。
// 结构从实际议事档案标本中长出，不预设执行字段。
// Content 当前为纯文本，未来可扩展为结构化内容（如 Markdown、富文本、字段化陈述）。
type Resolution struct {
	ID      string `json:"id"`
	Title   string `json:"title"`
	Content string `json:"content"`
}
