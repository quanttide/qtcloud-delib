package resolution_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/quanttide/qtcloud-delib-provider/internal/resolution"
	resolutiongorm "github.com/quanttide/qtcloud-delib-provider/internal/resolution/gorm"
)

func newTestMux(t *testing.T) *http.ServeMux {
	t.Helper()
	db := setupDB(t)
	svc := resolution.NewService(db, resolutiongorm.NewResolutionRepo())
	mux := http.NewServeMux()
	resolution.NewHandler(svc).Register(mux, func(h http.Handler) http.Handler {
		return h // 测试透传（鉴权中间件单独测试）
	})
	return mux
}

func TestListResolutions(t *testing.T) {
	mux := newTestMux(t)
	req := httptest.NewRequest(http.MethodGet, "/resolutions", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

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

func TestCreateResolution(t *testing.T) {
	mux := newTestMux(t)
	payload := `{"name":"weekly-vote","title":"周会实行记名表决制","content":"重大事项记名表决。","category":"治理"}`
	req := httptest.NewRequest(http.MethodPost, "/resolutions", bytes.NewBufferString(payload))
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("status = %d, want %d; body = %s", rec.Code, http.StatusCreated, rec.Body.String())
	}
	var created resolution.Resolution
	if err := json.Unmarshal(rec.Body.Bytes(), &created); err != nil {
		t.Fatalf("decode body: %v", err)
	}
	if created.ID == "" || created.Name != "weekly-vote" || created.Category != "治理" {
		t.Fatalf("created = %+v", created)
	}
}

func TestCreateResolutionInvalid(t *testing.T) {
	mux := newTestMux(t)
	req := httptest.NewRequest(http.MethodPost, "/resolutions", bytes.NewBufferString(`{"title":"缺 name"}`))
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestCreateResolutionBadBody(t *testing.T) {
	mux := newTestMux(t)
	req := httptest.NewRequest(http.MethodPost, "/resolutions", bytes.NewBufferString(`{invalid`))
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestCreateResolutionDuplicateName(t *testing.T) {
	mux := newTestMux(t)
	payload := `{"name":"weekly-vote","title":"周会实行记名表决制"}`
	for i := 0; i < 2; i++ {
		req := httptest.NewRequest(http.MethodPost, "/resolutions", bytes.NewBufferString(payload))
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if i == 0 {
			if rec.Code != http.StatusCreated {
				t.Fatalf("first create: status = %d", rec.Code)
			}
			continue
		}
		if rec.Code != http.StatusConflict {
			t.Fatalf("duplicate create: status = %d, want %d; body = %s", rec.Code, http.StatusConflict, rec.Body.String())
		}
	}
}
