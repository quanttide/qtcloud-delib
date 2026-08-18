package seed

import (
	"strings"
	"testing"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"github.com/quanttide/qtcloud-delib-provider/internal/topic"
)

func openTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{TranslateError: true})
	if err != nil {
		t.Fatalf("open db: %v", err)
	}
	if err := db.AutoMigrate(&topic.Topic{}); err != nil {
		t.Fatalf("migrate: %v", err)
	}
	return db
}

func TestImportAll(t *testing.T) {
	db := openTestDB(t)

	imported, updated, err := Import(db)
	if err != nil {
		t.Fatalf("import: %v", err)
	}
	if imported != 243 {
		t.Errorf("imported = %d, want 243", imported)
	}
	if updated != 0 {
		t.Errorf("updated = %d, want 0", updated)
	}

	var count int64
	if err := db.Model(&topic.Topic{}).Count(&count).Error; err != nil {
		t.Fatalf("count: %v", err)
	}
	if count != 243 {
		t.Errorf("total topics = %d, want 243", count)
	}
}

func TestImportIdempotent(t *testing.T) {
	db := openTestDB(t)

	if _, _, err := Import(db); err != nil {
		t.Fatalf("first import: %v", err)
	}
	imported, updated, err := Import(db)
	if err != nil {
		t.Fatalf("second import: %v", err)
	}
	if imported != 0 {
		t.Errorf("second import imported = %d, want 0", imported)
	}
	if updated != 243 {
		t.Errorf("second import updated = %d, want 243", updated)
	}
}

func TestImportKeepsStatusOnReimport(t *testing.T) {
	db := openTestDB(t)
	if _, _, err := Import(db); err != nil {
		t.Fatalf("import: %v", err)
	}

	// 模拟已有表决进度后重新 seed：status/附议/票数不得被重置
	var t0 topic.Topic
	if err := db.Model(&topic.Topic{}).Where("name = ?", "proposal-m-01").First(&t0).Error; err != nil {
		t.Fatalf("find proposal-m-01: %v", err)
	}
	t0.Status = topic.StatusSeconded
	t0.SeconderIDs = []string{"u-1", "u-2"}
	t0.Votes = topic.VoteResult{For: 1}
	if err := db.Model(&topic.Topic{}).Where("id = ?", t0.ID).Updates(map[string]any{
		"status": t0.Status, "seconder_ids_json": `["u-1","u-2"]`, "votes_json": `{"for":1,"against":0,"abstain":0}`,
	}).Error; err != nil {
		t.Fatalf("simulate progress: %v", err)
	}

	if _, _, err := Import(db); err != nil {
		t.Fatalf("reimport: %v", err)
	}
	var after topic.Topic
	if err := db.Model(&topic.Topic{}).Where("name = ?", "proposal-m-01").First(&after).Error; err != nil {
		t.Fatalf("find after: %v", err)
	}
	if after.Status != topic.StatusSeconded {
		t.Errorf("status reset to %q, want %q", after.Status, topic.StatusSeconded)
	}
	if len(after.SeconderIDs) != 0 {
		t.Errorf("seconders reset: %v", after.SeconderIDs)
	}
	if after.Votes.For != 0 || after.Votes.Against != 0 {
		t.Errorf("votes reset: %+v", after.Votes)
	}
}

func TestImportSampleEntry(t *testing.T) {
	db := openTestDB(t)
	if _, _, err := Import(db); err != nil {
		t.Fatalf("import: %v", err)
	}

	var e topic.Topic
	if err := db.Model(&topic.Topic{}).Where("name = ?", "proposal-m-01").First(&e).Error; err != nil {
		t.Fatalf("find: %v", err)
	}
	if e.LedgerNo != "M-01" {
		t.Errorf("ledgerNo = %q, want M-01", e.LedgerNo)
	}
	if e.Source != "2026年第1周-提案1" {
		t.Errorf("source = %q", e.Source)
	}
	if e.Title != "合伙人决议" {
		t.Errorf("title = %q", e.Title)
	}
	if e.Category != "提案" {
		t.Errorf("category = %q", e.Category)
	}
	if e.Status != topic.StatusProposed {
		t.Errorf("status = %q, want proposed", e.Status)
	}
	if e.Content == "" || !strings.Contains(e.Content, "【动议内容】") || !strings.Contains(e.Content, "【背景】") || !strings.Contains(e.Content, "【理由】") {
		t.Errorf("content missing sections: %.60s", e.Content)
	}
}

func TestAllNamesUnique(t *testing.T) {
	db := openTestDB(t)
	if _, _, err := Import(db); err != nil {
		t.Fatalf("import: %v", err)
	}

	var names []string
	if err := db.Model(&topic.Topic{}).Pluck("name", &names).Error; err != nil {
		t.Fatalf("pluck: %v", err)
	}
	seen := map[string]bool{}
	for _, n := range names {
		if seen[n] {
			t.Errorf("duplicate name %q", n)
		}
		seen[n] = true
	}
}
