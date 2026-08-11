package httpserver

// JWT 鉴权中间件测试：RS256 签发 → 验签通过；无 token/伪造 → 401。

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

func genKey(t *testing.T) (pubB64 string, signKey *rsa.PrivateKey) {
	t.Helper()
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	der, err := x509.MarshalPKIXPublicKey(&key.PublicKey)
	if err != nil {
		t.Fatal(err)
	}
	pubPEM := pem.EncodeToMemory(&pem.Block{Type: "PUBLIC KEY", Bytes: der})
	return base64.StdEncoding.EncodeToString(pubPEM), key
}

func signToken(t *testing.T, key *rsa.PrivateKey) string {
	t.Helper()
	tok, err := jwt.NewWithClaims(jwt.SigningMethodRS256, jwt.MapClaims{
		"sub": "test-user",
		"exp": time.Now().Add(time.Hour).Unix(),
	}).SignedString(key)
	if err != nil {
		t.Fatal(err)
	}
	return tok
}

func TestRequireJWT(t *testing.T) {
	pubB64, key := genKey(t)
	_, verifyKey, err := PublicKeyFromEnv(pubB64)
	if err != nil {
		t.Fatal(err)
	}

	handler := RequireJWT(verifyKey)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	// 无 token → 401
	req := httptest.NewRequest("GET", "/", nil)
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, req)
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("no token: %d, want 401", w.Code)
	}

	// 有效 token → 200
	tok := signToken(t, key)
	req = httptest.NewRequest("GET", "/", nil)
	req.Header.Set("Authorization", "Bearer "+tok)
	w = httptest.NewRecorder()
	handler.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("valid token: %d, want 200", w.Code)
	}

	// 伪造 token（HS256 签名）→ 401
	forged, _ := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{"sub": "x"}).SignedString([]byte("secret"))
	req = httptest.NewRequest("GET", "/", nil)
	req.Header.Set("Authorization", "Bearer "+forged)
	w = httptest.NewRecorder()
	handler.ServeHTTP(w, req)
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("forged token: %d, want 401", w.Code)
	}
}
