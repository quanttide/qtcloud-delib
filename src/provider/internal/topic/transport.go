package topic

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/quanttide/qtcloud-delib-provider/internal/httpserver"
)

// Handler 议题 API（五流程操作）。
type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// Register 注册路由（wrap 为 JWT 鉴权中间件）。
func (h *Handler) Register(mux *http.ServeMux, wrap func(http.Handler) http.Handler) {
	mux.Handle("GET /topics", wrap(http.HandlerFunc(h.handleList)))
	mux.Handle("POST /topics", wrap(http.HandlerFunc(h.handleCreate)))
	mux.Handle("GET /topics/{id}", wrap(http.HandlerFunc(h.handleGet)))
	mux.Handle("POST /topics/{id}/second", wrap(http.HandlerFunc(h.handleSecond)))
	mux.Handle("POST /topics/{id}/debate", wrap(http.HandlerFunc(h.handleDebate)))
	mux.Handle("POST /topics/{id}/vote", wrap(http.HandlerFunc(h.handleVote)))
	mux.Handle("POST /topics/{id}/close", wrap(http.HandlerFunc(h.handleClose)))
}

func (h *Handler) handleList(w http.ResponseWriter, r *http.Request) {
	topics, err := h.svc.List(r.Context())
	if err != nil {
		httpserver.WriteError(w, http.StatusInternalServerError, "list failed")
		return
	}
	httpserver.WriteJSON(w, http.StatusOK, map[string]any{"topics": topics})
}

func (h *Handler) handleCreate(w http.ResponseWriter, r *http.Request) {
	var t Topic
	if err := json.NewDecoder(r.Body).Decode(&t); err != nil {
		httpserver.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	t.ProposerID = httpserver.UserID(r)
	created, err := h.svc.Create(r.Context(), &t)
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidInput):
			httpserver.WriteError(w, http.StatusBadRequest, "title required")
		case errors.Is(err, ErrDuplicateName):
			httpserver.WriteError(w, http.StatusConflict, "name already exists")
		default:
			httpserver.WriteError(w, http.StatusInternalServerError, "create failed")
		}
		return
	}
	httpserver.WriteJSON(w, http.StatusCreated, created)
}

func (h *Handler) handleGet(w http.ResponseWriter, r *http.Request) {
	t, err := h.svc.get(r.PathValue("id"))
	if errors.Is(err, ErrNotFound) {
		httpserver.WriteError(w, http.StatusNotFound, "topic not found")
		return
	}
	if err != nil {
		httpserver.WriteError(w, http.StatusInternalServerError, "get failed")
		return
	}
	httpserver.WriteJSON(w, http.StatusOK, t)
}

func (h *Handler) handleSecond(w http.ResponseWriter, r *http.Request) {
	t, err := h.svc.Second(r.Context(), r.PathValue("id"), httpserver.UserID(r))
	h.writeTransition(w, t, err)
}

func (h *Handler) handleDebate(w http.ResponseWriter, r *http.Request) {
	t, err := h.svc.Debate(r.Context(), r.PathValue("id"))
	h.writeTransition(w, t, err)
}

func (h *Handler) handleVote(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Choice string `json:"choice"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpserver.WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	t, err := h.svc.Vote(r.Context(), r.PathValue("id"), httpserver.UserID(r), req.Choice)
	h.writeTransition(w, t, err)
}

func (h *Handler) handleClose(w http.ResponseWriter, r *http.Request) {
	t, err := h.svc.Close(r.Context(), r.PathValue("id"))
	h.writeTransition(w, t, err)
}

func (h *Handler) writeTransition(w http.ResponseWriter, t *Topic, err error) {
	switch {
	case err == nil:
		httpserver.WriteJSON(w, http.StatusOK, t)
	case errors.Is(err, ErrNotFound):
		httpserver.WriteError(w, http.StatusNotFound, "topic not found")
	case errors.Is(err, ErrBadState):
		httpserver.WriteError(w, http.StatusConflict, "invalid state transition")
	case errors.Is(err, ErrAlreadyVoted):
		httpserver.WriteError(w, http.StatusConflict, "already seconded or voted")
	case errors.Is(err, ErrInvalidInput):
		httpserver.WriteError(w, http.StatusBadRequest, "invalid input")
	default:
		httpserver.WriteError(w, http.StatusInternalServerError, "operation failed")
	}
}
