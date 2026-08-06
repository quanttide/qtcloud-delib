package seed

import (
	"net/http"

	"gorm.io/gorm"

	"github.com/quanttide/qtcloud-delib-provider/internal/httpserver"
)

// Register 挂载种子导入端点（POST /seed）。
// token 为空时不挂载（本地开发用 cmd/seed，不需要该端点）。
// 端点校验 X-Seed-Token 请求头，防止公网任意触发；导入幂等（新增 + 按 name 同步更新）。
func Register(mux *http.ServeMux, db *gorm.DB, token, apiURL, rawBaseURL string) {
	if token == "" {
		return
	}
	mux.HandleFunc("POST /seed", func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("X-Seed-Token") != token {
			httpserver.WriteError(w, http.StatusUnauthorized, "unauthorized")
			return
		}
		imported, updated, err := Import(r.Context(), db, apiURL, rawBaseURL)
		if err != nil {
			httpserver.WriteError(w, http.StatusInternalServerError, "seed failed")
			return
		}
		httpserver.WriteJSON(w, http.StatusOK, map[string]int{"imported": imported, "updated": updated})
	})
}
