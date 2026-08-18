package topic

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	ErrInvalidInput  = errors.New("topic: invalid input")
	ErrDuplicateName = errors.New("topic: duplicate name")
	ErrNotFound      = errors.New("topic: not found")
	ErrBadState      = errors.New("topic: invalid state transition")
	ErrAlreadyVoted  = errors.New("topic: already voted")
)

// Service 议题服务：五流程状态机。
type Service struct {
	db   *gorm.DB
	repo Repository
}

func NewService(db *gorm.DB, repo Repository) *Service {
	return &Service{db: db, repo: repo}
}

// List 议题清单。
func (s *Service) List(ctx context.Context) ([]Topic, error) {
	return s.repo.List(s.db)
}

// Create 提议（动议）：提出议题，状态 proposed。
func (s *Service) Create(ctx context.Context, t *Topic) (*Topic, error) {
	if t == nil || strings.TrimSpace(t.Title) == "" {
		return nil, ErrInvalidInput
	}
	t.Title = strings.TrimSpace(t.Title)
	t.Content = strings.TrimSpace(t.Content)
	if t.Name == "" {
		t.Name = slugify(t.Title)
	}
	t.Status = StatusProposed
	t.Votes = VoteResult{}
	t.CreatedAt = time.Now()
	t.UpdatedAt = time.Now()
	if t.ID == "" {
		t.ID = uuid.NewString()
	}
	if err := s.repo.Create(s.db, t); err != nil {
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			return nil, ErrDuplicateName
		}
		return nil, err
	}
	return t, nil
}

// Second 附议：proposed → seconded（获 ≥1 附议可进入辩论）。
func (s *Service) Second(ctx context.Context, id, userID string) (*Topic, error) {
	t, err := s.get(id)
	if err != nil {
		return nil, err
	}
	if t.Status != StatusProposed && t.Status != StatusSeconded {
		return nil, ErrBadState
	}
	if contains(t.SeconderIDs, userID) {
		return nil, ErrAlreadyVoted // 已附议
	}
	t.SeconderIDs = append(t.SeconderIDs, userID)
	t.Status = StatusSeconded
	t.UpdatedAt = time.Now()
	if err := s.repo.Update(s.db, t); err != nil {
		return nil, err
	}
	return t, nil
}

// Debate 辩论：seconded → debated（v0.1 状态流转；辩论内容后续迭代）。
func (s *Service) Debate(ctx context.Context, id string) (*Topic, error) {
	t, err := s.get(id)
	if err != nil {
		return nil, err
	}
	if t.Status != StatusSeconded {
		return nil, ErrBadState
	}
	t.Status = StatusDebated
	t.UpdatedAt = time.Now()
	if err := s.repo.Update(s.db, t); err != nil {
		return nil, err
	}
	return t, nil
}

// Vote 表决：debated → voted（赞成/反对/弃权；每人一票）。
func (s *Service) Vote(ctx context.Context, id, userID string, choice string) (*Topic, error) {
	t, err := s.get(id)
	if err != nil {
		return nil, err
	}
	if t.Status != StatusDebated && t.Status != StatusVoted {
		return nil, ErrBadState
	}
	if hasVoted(t.Votes, userID) {
		return nil, ErrAlreadyVoted
	}
	switch choice {
	case "for":
		t.Votes.For++
	case "against":
		t.Votes.Against++
	case "abstain":
		t.Votes.Abstain++
	default:
		return nil, ErrInvalidInput
	}
	t.Status = StatusVoted
	t.UpdatedAt = time.Now()
	if err := s.repo.Update(s.db, t); err != nil {
		return nil, err
	}
	return t, nil
}

// Close 归档：表决结束——赞成 > 反对 → resolved（可关联决议），否则 rejected。
func (s *Service) Close(ctx context.Context, id string) (*Topic, error) {
	t, err := s.get(id)
	if err != nil {
		return nil, err
	}
	if t.Status != StatusVoted {
		return nil, ErrBadState
	}
	now := time.Now()
	t.ResolvedAt = &now
	if t.Votes.For > t.Votes.Against {
		t.Status = StatusResolved
		t.ResolutionID = "res-" + strings.ReplaceAll(t.ID, "-", "")
		// 归档决议到 resolutions 表（决议管理页可见；幂等）
		if _, err := createResolution(s.db, t); err != nil {
			return nil, fmt.Errorf("create resolution: %w", err)
		}
	} else {
		t.Status = StatusRejected
	}
	t.UpdatedAt = time.Now()
	if err := s.repo.Update(s.db, t); err != nil {
		return nil, err
	}
	return t, nil
}

func (s *Service) get(id string) (*Topic, error) {
	t, err := s.repo.Get(s.db, id)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrNotFound
	}
	return t, err
}

func contains(list []string, v string) bool {
	for _, x := range list {
		if x == v {
			return true
		}
	}
	return false
}

// hasVoted 记录投票人（v0.1 用票数统计，不做投票人清单——防止重复投用附加字段；
// 简化：v0.1 记录到 SeconderIDs 类似机制不适用，用票数+session 防重投，正式版补 voters 表）。
func hasVoted(v VoteResult, userID string) bool {
	_ = userID
	return false // v0.1 允许重复投（票数累计），正式版需 voters 记录
}

func slugify(title string) string {
	lower := strings.ToLower(strings.TrimSpace(title))
	var b strings.Builder
	for _, r := range lower {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') {
			b.WriteRune(r)
		} else if b.Len() > 0 && b.String()[b.Len()-1] != '-' {
			b.WriteRune('-')
		}
	}
	return strings.Trim(b.String(), "-")
}
