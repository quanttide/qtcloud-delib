// Package main 服务端入口：加载配置、组装依赖、启动服务。
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/quanttide/qtcloud-delib-provider/internal/app"
	topicseed "github.com/quanttide/qtcloud-delib-provider/internal/topic/seed"
)

func main() {
	addr := flag.String("addr", ":8080", "HTTP 监听地址")
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx, *addr); err != nil {
		log.Fatalf("server: %v", err)
	}
}

// run 打开数据库、组装路由并启动服务（含优雅关闭）。
func run(ctx context.Context, addr string) error {
	db, err := app.OpenDB()
	if err != nil {
		return err
	}
	// SEED_LEDGER=1：启动时幂等导入议事档案动议（FC 容器无法 exec，用 env 触发）
	if os.Getenv("SEED_LEDGER") == "1" {
		imported, updated, err := topicseed.Import(db)
		if err != nil {
			return fmt.Errorf("seed ledger: %w", err)
		}
		log.Printf("ledger seed done: imported %d, updated %d", imported, updated)
	}
	mux, err := app.BuildMux(db)
	if err != nil {
		return err
	}

	ln, err := net.Listen("tcp", addr)
	if err != nil {
		return err
	}
	log.Printf("API server listening on %s", ln.Addr())

	srv := &http.Server{Handler: mux}
	go func() {
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := srv.Shutdown(shutdownCtx); err != nil {
			log.Printf("shutdown: %v", err)
		}
	}()
	if err := srv.Serve(ln); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	return nil
}
