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

// Register 注册决议路由（wrap 为 JWT 鉴权中间件，全部端点要求登录）。
func (h *Handler) Register(mux *http.ServeMux, wrap func(http.Handler) http.Handler) {
	mux.Handle("GET /resolutions", wrap(http.HandlerFunc(h.handleList)))
	mux.Handle("POST /resolutions", wrap(http.HandlerFunc(h.handleCreate)))
	mux.Handle("DELETE /resolutions/{name}", wrap(http.HandlerFunc(h.handleDelete)))
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

// handleDelete 删除决议：DELETE /resolutions/{name}
func (h *Handler) handleDelete(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")
	if err := h.svc.Delete(r.Context(), name); err != nil {
		switch {
		case errors.Is(err, ErrInvalidInput):
			httpserver.WriteError(w, http.StatusBadRequest, "name is required")
		case errors.Is(err, ErrNotFound):
			httpserver.WriteError(w, http.StatusNotFound, "resolution not found")
		default:
			httpserver.WriteError(w, http.StatusInternalServerError, "delete failed")
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
