package model

import "testing"

func TestResolution(t *testing.T) {
	r := Resolution{
		ID:      "2026-W32-01",
		Title:   "周会实行记名表决制",
		Content: "重大事项记名表决，常规事项不记名，结果留痕存档。",
	}

	if r.ID != "2026-W32-01" {
		t.Errorf("ID = %q, want %q", r.ID, "2026-W32-01")
	}
	if r.Title != "周会实行记名表决制" {
		t.Errorf("Title = %q, want %q", r.Title, "周会实行记名表决制")
	}
	if r.Content == "" {
		t.Error("Content should not be empty")
	}
}
