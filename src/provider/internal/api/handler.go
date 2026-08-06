// Package api 提供 HTTP 端点与中间件。
package api

import (
	"encoding/json"
	"log/slog"
	"net/http"

	"github.com/quanttide/qtcloud-delib-provider/internal/model"
	"github.com/quanttide/qtcloud-delib-provider/internal/store"
)

// ResolutionHandler 决议资源端点。
type ResolutionHandler struct {
	store *store.ResolutionStore
}

func NewResolutionHandler(st *store.ResolutionStore) *ResolutionHandler {
	return &ResolutionHandler{store: st}
}

// List 决议清单：GET /resolutions
func (h *ResolutionHandler) List(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"resolutions": []model.Resolution{
			{ID: "2026-W32-01", Title: "周会实行记名表决制", Content: "重大事项记名表决，常规事项不记名。", Category: "治理"},
		},
	})
}

// Create 创建决议：POST /resolutions
func (h *ResolutionHandler) Create(w http.ResponseWriter, r *http.Request) {
	var res model.Resolution
	if err := json.NewDecoder(r.Body).Decode(&res); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	id, err := h.store.Create(&res)
	if err != nil {
		slog.Error("create resolution", "error", err)
		writeError(w, http.StatusInternalServerError, "create failed")
		return
	}
	res.ID = id
	writeJSON(w, http.StatusCreated, res)
}
