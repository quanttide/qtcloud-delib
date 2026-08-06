// Package httpserver 提供 HTTP 响应工具。
package httpserver

import (
	"encoding/json"
	"log/slog"
	"net/http"
)

// WriteJSON 统一 JSON 响应。
func WriteJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(data); err != nil {
		slog.Error("encode response", "error", err)
	}
}

// WriteError 统一错误响应。
func WriteError(w http.ResponseWriter, status int, message string) {
	WriteJSON(w, status, map[string]string{"error": message})
}
