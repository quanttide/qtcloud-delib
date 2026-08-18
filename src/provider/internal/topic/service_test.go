package topic

// 议题五流程状态机测试。

import (
	"context"
	"testing"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{TranslateError: true})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&Topic{}); err != nil {
		t.Fatal(err)
	}
	return db
}

func newService(t *testing.T) *Service {
	return NewService(setupDB(t), NewRepoForTest())
}

func TestTopicFiveFlows(t *testing.T) {
	svc := newService(t)
	ctx := context.Background()

	// 1. 动议
	topic, err := svc.Create(ctx, &Topic{Title: "周会实行记名表决制", Content: "自本周起重大事项记名表决", ProposerID: "u-1"})
	if err != nil {
		t.Fatal(err)
	}
	if topic.Status != StatusProposed {
		t.Fatalf("status = %s, want proposed", topic.Status)
	}

	// 2. 附议（1 人）→ seconded
	topic, err = svc.Second(ctx, topic.ID, "u-2")
	if err != nil {
		t.Fatal(err)
	}
	if topic.Status != StatusSeconded || len(topic.SeconderIDs) != 1 {
		t.Fatalf("after second: status=%s seconders=%d", topic.Status, len(topic.SeconderIDs))
	}

	// 3. 辩论（已附议）→ debated
	topic, err = svc.Debate(ctx, topic.ID)
	if err != nil {
		t.Fatal(err)
	}
	if topic.Status != StatusDebated {
		t.Fatalf("status = %s, want debated", topic.Status)
	}

	// 4. 表决（3 票：2 赞成 1 反对）
	for _, v := range []struct{ user, choice string }{{"u-3", "for"}, {"u-4", "for"}, {"u-5", "against"}} {
		if _, err := svc.Vote(ctx, topic.ID, v.user, v.choice); err != nil {
			t.Fatalf("vote %s: %v", v.user, err)
		}
	}
	topic, _ = svc.get(topic.ID)
	if topic.Votes.For != 2 || topic.Votes.Against != 1 {
		t.Fatalf("votes = %+v", topic.Votes)
	}

	// 5. 归档 → resolved（赞成 > 反对）
	topic, err = svc.Close(ctx, topic.ID)
	if err != nil {
		t.Fatal(err)
	}
	if topic.Status != StatusResolved || topic.ResolutionID == "" {
		t.Fatalf("close: status=%s resId=%s", topic.Status, topic.ResolutionID)
	}
	if topic.ResolvedAt == nil {
		t.Fatal("resolved_at should be set")
	}
}

func TestTopicRejected(t *testing.T) {
	svc := newService(t)
	ctx := context.Background()

	topic, _ := svc.Create(ctx, &Topic{Title: "否决案", ProposerID: "u-1"})
	_, _ = svc.Second(ctx, topic.ID, "u-2")
	_, _ = svc.Debate(ctx, topic.ID)
	_, _ = svc.Vote(ctx, topic.ID, "u-3", "against")
	_, _ = svc.Vote(ctx, topic.ID, "u-4", "against")

	topic, err := svc.Close(ctx, topic.ID)
	if err != nil {
		t.Fatal(err)
	}
	if topic.Status != StatusRejected {
		t.Fatalf("status = %s, want rejected", topic.Status)
	}
}

func TestTopicBadTransitions(t *testing.T) {
	svc := newService(t)
	ctx := context.Background()

	topic, _ := svc.Create(ctx, &Topic{Title: "非法流转", ProposerID: "u-1"})

	// 未附议直接辩论 → ErrBadState
	if _, err := svc.Debate(ctx, topic.ID); err != ErrBadState {
		t.Fatalf("debate without second: %v, want ErrBadState", err)
	}
	// 未辩论直接表决 → ErrBadState
	if _, err := svc.Vote(ctx, topic.ID, "u-2", "for"); err != ErrBadState {
		t.Fatalf("vote without debate: %v, want ErrBadState", err)
	}
	// 未表决直接归档 → ErrBadState
	if _, err := svc.Close(ctx, topic.ID); err != ErrBadState {
		t.Fatalf("close without vote: %v, want ErrBadState", err)
	}
	// 非法表决选项
	_, _ = svc.Second(ctx, topic.ID, "u-2")
	_, _ = svc.Debate(ctx, topic.ID)
	if _, err := svc.Vote(ctx, topic.ID, "u-3", "maybe"); err != ErrInvalidInput {
		t.Fatalf("invalid choice: %v, want ErrInvalidInput", err)
	}
}
