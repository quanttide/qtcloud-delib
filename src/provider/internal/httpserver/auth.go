// Package httpserver 提供 HTTP 响应工具与 JWT 鉴权中间件。
package httpserver

// JWT 验签中间件：RS256 公钥（与 qtcloud-auth 共享密钥对）。
// 未携带有效 Bearer JWT 一律 401（fail-closed）。

import (
	"encoding/base64"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

// PublicKeyFromEnv 从 JWT_PUBLIC_KEY（base64(PEM) 单行）解析 RSA 公钥。
// GitHub Actions env 不支持多行值，故统一 base64 编码（与 qtcloud-auth 的私钥一致）。
func PublicKeyFromEnv(encoded string) (*jwt.SigningMethodRSA, interface{}, error) {
	raw, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		return nil, nil, fmt.Errorf("auth: JWT_PUBLIC_KEY base64 decode: %w", err)
	}
	block, _ := pem.Decode(raw)
	if block == nil {
		return nil, nil, fmt.Errorf("auth: invalid JWT public key PEM")
	}
	pub, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		return nil, nil, fmt.Errorf("auth: parse public key: %w", err)
	}
	return jwt.SigningMethodRS256, pub, nil
}

// RequireJWT 返回验签中间件：请求需带 Authorization: Bearer <RS256 JWT>。
func RequireJWT(verifyKey interface{}) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ah := r.Header.Get("Authorization")
			if !strings.HasPrefix(ah, "Bearer ") {
				WriteError(w, http.StatusUnauthorized, "missing or invalid authorization header")
				return
			}
			token, err := jwt.Parse(strings.TrimPrefix(ah, "Bearer "), func(t *jwt.Token) (any, error) {
				if _, ok := t.Method.(*jwt.SigningMethodRSA); !ok {
					return nil, jwt.ErrSignatureInvalid
				}
				return verifyKey, nil
			})
			if err != nil || !token.Valid {
				WriteError(w, http.StatusUnauthorized, "invalid or expired token")
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
