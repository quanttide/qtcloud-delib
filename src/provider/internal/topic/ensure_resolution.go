package topic

import (
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/quanttide/qtcloud-delib-provider/internal/resolution"
	resolutiongorm "github.com/quanttide/qtcloud-delib-provider/internal/resolution/gorm"
)

// createResolution 表决通过后归档决议：按 name=ResolutionID 已存在则跳过（幂等）。
// 返回是否实际创建。
func createResolution(db *gorm.DB, t *Topic) (bool, error) {
	repo := resolutiongorm.NewResolutionRepo()
	if _, err := repo.GetByName(db, t.ResolutionID); err == nil {
		return false, nil // 已归档（重复 Close 兜底）
	} else if err != gorm.ErrRecordNotFound {
		return false, err
	}
	res := resolution.Resolution{
		ID:       uuid.NewString(),
		Name:     t.ResolutionID,
		Title:    t.Title,
		Content:  fmt.Sprintf("%s\n\n【表决】赞成 %d / 反对 %d / 弃权 %d", t.Content, t.Votes.For, t.Votes.Against, t.Votes.Abstain),
		Category: t.Category,
	}
	return true, repo.Create(db, &res)
}

// EnsureResolutionsForResolved 启动幂等补建：status=resolved 但 resolutions 表缺记录的议题，
// 按 ResolutionID 创建决议（历史遗留/中途变更兜底；重复执行无害）。
// 返回（创建数, 已存在跳过数）。
func EnsureResolutionsForResolved(db *gorm.DB) (created, skipped int, err error) {
	var rows []Topic
	if err := db.Model(&Topic{}).
		Where("status = ? AND resolution_id != ''", StatusResolved).
		Find(&rows).Error; err != nil {
		return 0, 0, err
	}
	for i := range rows {
		t := rows[i]
		if err := json.Unmarshal([]byte(t.VotesJSON), &t.Votes); err != nil {
			t.Votes = VoteResult{}
		}
		ok, err := createResolution(db, &t)
		if err != nil {
			return created, skipped, fmt.Errorf("create %s: %w", t.ResolutionID, err)
		}
		if ok {
			created++
		} else {
			skipped++
		}
	}
	return created, skipped, nil
}
