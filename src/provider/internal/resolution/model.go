// Package resolution 提供决议领域：模型、存储、服务与传输层。
package resolution

// Resolution 决议：决策记录。
//
// ID 为 UUID；Name 为决议标识（slug，取自文件名）。
// Title 概括"决定了什么"，Content 展开决议陈述。
// Category 标注决议分类（如：治理、审计、档案、技术等）。
// 结构从实际议事档案标本中长出，不预设执行字段。
// Content 当前为纯文本，未来可扩展为结构化内容（如 Markdown、富文本、字段化陈述）。
type Resolution struct {
	ID       string `gorm:"primaryKey;size:36;comment:决议ID（UUID）" json:"id"`
	Name     string `gorm:"size:64;uniqueIndex;comment:决议标识（slug，取自文件名）" json:"name"`
	Title    string `gorm:"size:255;comment:决议标题" json:"title"`
	Content  string `gorm:"type:text;comment:决议陈述" json:"content"`
	Category string `gorm:"size:32;comment:决议分类" json:"category"`
}
