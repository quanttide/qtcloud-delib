// Package main 决议种子数据导入入口。
package main

import (
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/quanttide/qtcloud-delib-provider/internal/app"
	"github.com/quanttide/qtcloud-delib-provider/internal/resolution/seed"
)

func main() {
	apiURL := flag.String("api-url", seed.DefaultAPIURL, "GitHub contents API 地址（决议目录）")
	rawBase := flag.String("raw-base", seed.DefaultRawBaseURL, "GitHub raw 基址（决议目录）")
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	db, err := app.OpenDB()
	if err != nil {
		log.Fatalf("open db: %v", err)
	}
	imported, updated, err := seed.Import(ctx, db, *apiURL, *rawBase)
	if err != nil {
		log.Fatalf("seed: %v", err)
	}
	log.Printf("seed done: imported %d, updated %d", imported, updated)
}
