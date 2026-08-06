package seed_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/quanttide/qtcloud-delib-provider/internal/resolution/seed"
)

func TestRegisterSeedEndpoint(t *testing.T) {
	apiURL, rawBase := fakeRepo(t)
	db := setupDB(t)

	mux := http.NewServeMux()
	seed.Register(mux, db, "test-token", apiURL, rawBase)

	// 未配置 token 时不挂载
	muxNoToken := http.NewServeMux()
	seed.Register(muxNoToken, db, "", apiURL, rawBase)
	req := httptest.NewRequest(http.MethodPost, "/seed", nil)
	rec := httptest.NewRecorder()
	muxNoToken.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("no-token mux: status = %d, want 404（未配置不挂载）", rec.Code)
	}

	// 错误 token → 401
	req = httptest.NewRequest(http.MethodPost, "/seed", nil)
	req.Header.Set("X-Seed-Token", "wrong")
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("wrong token: status = %d, want 401", rec.Code)
	}

	// 正确 token → 200 + 统计
	req = httptest.NewRequest(http.MethodPost, "/seed", nil)
	req.Header.Set("X-Seed-Token", "test-token")
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("seed: status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), `"imported":1`) {
		t.Fatalf("body = %s, want imported 1", rec.Body.String())
	}

	// 幂等：再次触发为更新
	req = httptest.NewRequest(http.MethodPost, "/seed", nil)
	req.Header.Set("X-Seed-Token", "test-token")
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), `"updated":1`) {
		t.Fatalf("re-seed: status = %d, body = %s", rec.Code, rec.Body.String())
	}
}
