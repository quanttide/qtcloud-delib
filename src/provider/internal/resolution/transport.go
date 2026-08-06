package resolution

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/quanttide/qtcloud-delib-provider/internal/httpserver"
)

// Handler 决议 API。
type Handler struct {
	svc *Service
}

// NewHandler 创建决议 API。
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// Register 注册决议路由。
func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /resolutions", h.handleList)
	mux.HandleFunc("POST /resolutions", h.handleCreate)
}

// handleList 决议清单：GET /resolutions
func (h *Handler) handleList(w http.ResponseWriter, r *http.Request) {
	res, err := h.svc.List(r.Context())
	if err != nil {
		httpserver.WriteError(w, http.StatusInternalServerError, "list failed")
		return
	}
	httpserver.WriteJSON(w, http.StatusOK, map[string]any{"resolutions": res})
}

// handleCreate 创建决议：POST /resolutions
func (h *Handler) handleCreate(w http.ResponseWriter, r *http.Request) {
	var res Resolution
	if err := json.NewDecoder(r.Body).Decode(&res); err != nil {
		httpserver.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	created, err := h.svc.Create(r.Context(), &res)
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidInput):
			httpserver.WriteError(w, http.StatusBadRequest, "name and title are required")
		case errors.Is(err, ErrDuplicateName):
			httpserver.WriteError(w, http.StatusConflict, "name already exists")
		default:
			httpserver.WriteError(w, http.StatusInternalServerError, "create failed")
		}
		return
	}
	httpserver.WriteJSON(w, http.StatusCreated, created)
}
