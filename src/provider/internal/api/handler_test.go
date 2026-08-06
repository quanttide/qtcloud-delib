package api

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/quanttide/qtcloud-delib-provider/internal/store"
)

func TestResolutionList(t *testing.T) {
	st := store.NewMemoryStore()
	handler := NewResolutionHandler(store.NewResolutionStore(st))

	req := httptest.NewRequest(http.MethodGet, "/resolutions", nil)
	rec := httptest.NewRecorder()
	handler.List(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("decode body: %v", err)
	}
	if _, ok := body["resolutions"]; !ok {
		t.Error("response should contain resolutions")
	}
}
