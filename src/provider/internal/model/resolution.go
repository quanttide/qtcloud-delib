// Package model 提供议事领域模型。
package model

// Resolution 决议：决策记录。
//
// Title 概括"决定了什么"，Description 展开决议陈述。
// 结构从实际议事档案标本中长出，不预设执行字段。
type Resolution struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description"`
}
