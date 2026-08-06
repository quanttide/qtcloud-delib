package api

import (
	"encoding/json"
	"log/slog"
	"net/http"
)

// writeJSON 统一 JSON 响应。
func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(data); err != nil {
		slog.Error("encode response", "error", err)
	}
}

// writeError 统一错误响应。
func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
