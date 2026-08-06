package model

import "testing"

func TestResolution(t *testing.T) {
	r := Resolution{
		ID:       "5914902c-1d03-496d-8f56-d3f627c17caf",
		Title:    "周会实行记名表决制",
		Content:  "重大事项记名表决，常规事项不记名，结果留痕存档。",
		Category: "治理",
	}

	if r.ID != "5914902c-1d03-496d-8f56-d3f627c17caf" {
		t.Errorf("ID = %q, want %q", r.ID, "5914902c-1d03-496d-8f56-d3f627c17caf")
	}
	if r.Title != "周会实行记名表决制" {
		t.Errorf("Title = %q, want %q", r.Title, "周会实行记名表决制")
	}
	if r.Content == "" {
		t.Error("Content should not be empty")
	}
	if r.Category != "治理" {
		t.Errorf("Category = %q, want %q", r.Category, "治理")
	}
}
