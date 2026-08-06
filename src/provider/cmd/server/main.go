// qtcloud-delib-provider 量潮议事云服务提供方入口。

package main

import (
	"log/slog"
	"net/http"
	"os"

	"github.com/quanttide/qtcloud-delib-provider/internal/api"
	"github.com/quanttide/qtcloud-delib-provider/internal/store"
)

func main() {
	// ── 存储（开发调试用内存实现，后续对接数据库） ──
	st := store.NewMemoryStore()
	resolutionStore := store.NewResolutionStore(st)

	// ── 决议处理器 ──
	handler := api.NewResolutionHandler(resolutionStore)

	// ── 路由 ──
	mux := http.NewServeMux()
	mux.HandleFunc("GET /resolutions", handler.List)
	mux.HandleFunc("POST /resolutions", handler.Create)

	// ── 启动 ──
	addr := getEnv("LISTEN_ADDR", ":8080")
	slog.Info("starting provider", "addr", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		slog.Error("server error", "error", err)
		os.Exit(1)
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
