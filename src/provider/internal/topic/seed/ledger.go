// Package seed 议题种子数据：议事档案台账（ledger.json）导入为动议（Topic）。
//
// 数据源：飞书议事档案-2026 导出，赵子奕整理为 11 类台账 243 条动议
// （量潮科技2026年台账-合并版.md → ledger.json，解析脚本见 /tmp/parse_ledger.py）。
// 幂等：按 Name（类别 slug + 台账编号）已存在则更新内容，否则创建。
package seed

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/quanttide/qtcloud-delib-provider/internal/topic"
	topicgorm "github.com/quanttide/qtcloud-delib-provider/internal/topic/gorm"
)

//go:embed ledger.json
var ledgerJSON []byte

// 台账类别 → 英文 slug（Name 唯一 key 前缀，避免各类台账 M 编号重复冲突）。
var categorySlug = map[string]string{
	"提案": "proposal", "研讨": "discussion", "澄清": "clarity", "复盘": "review",
	"计划": "plan", "报告": "report", "议事规则": "rules", "审计": "audit",
	"评估": "assessment", "议程": "agenda", "谈判": "negotiation",
}

// Entry 台账条目（ledger.json 结构）。
type Entry struct {
	LedgerNo string `json:"ledgerNo"`
	Category string `json:"category"`
	Title    string `json:"title"`
	Source   string `json:"source"`
	Content  string `json:"content"`
}

// Import 幂等导入议事档案动议（全部置 proposed 待附议）。
// 返回（新增数, 更新数）。
func Import(db *gorm.DB) (imported, updated int, err error) {
	var entries []Entry
	if err := json.Unmarshal(ledgerJSON, &entries); err != nil {
		return 0, 0, fmt.Errorf("parse ledger.json: %w", err)
	}

	repo := topicgorm.NewTopicRepo()
	for _, e := range entries {
		slug, ok := categorySlug[e.Category]
		if !ok {
			return imported, updated, fmt.Errorf("未知台账类别 %q（%s）", e.Category, e.LedgerNo)
		}
		name := fmt.Sprintf("%s-%s", slug, strings.ToLower(e.LedgerNo))
		now := time.Now()
		t := topic.Topic{
			Name:      name,
			Title:     e.Title,
			Content:   e.Content,
			Category:  e.Category,
			LedgerNo:  e.LedgerNo,
			Source:    e.Source,
			Status:    topic.StatusProposed,
			CreatedAt: now,
			UpdatedAt: now,
		}
		if _, err := repo.GetByName(db, name); err == nil {
			if err := repo.UpdateByName(db, name, &t); err != nil {
				return imported, updated, fmt.Errorf("update %s: %w", name, err)
			}
			updated++
			continue
		} else if err != gorm.ErrRecordNotFound {
			return imported, updated, fmt.Errorf("check %s: %w", name, err)
		}
		t.ID = uuid.NewString()
		if err := repo.Create(db, &t); err != nil {
			return imported, updated, fmt.Errorf("create %s: %w", name, err)
		}
		imported++
	}
	return imported, updated, nil
}
