// Package app 服务端组装：数据库打开、依赖注入与路由注册。
// cmd/server 与测试共用，保证装配一致。
package app

import (
	"fmt"
	"net/http"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"github.com/quanttide/qtcloud-delib-provider/internal/httpserver"
	"github.com/quanttide/qtcloud-delib-provider/internal/resolution"
	resolutiongorm "github.com/quanttide/qtcloud-delib-provider/internal/resolution/gorm"
)

// Open 打开数据库并迁移全部模型（driver: sqlite/postgres，dsn 对应驱动格式）。
func Open(driver, dsn string) (*gorm.DB, error) {
	var (
		db  *gorm.DB
		err error
	)
	switch driver {
	case "postgres":
		db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{TranslateError: true})
	default: // sqlite（开发默认）
		db, err = gorm.Open(sqlite.Open(dsn), &gorm.Config{TranslateError: true})
	}
	if err != nil {
		return nil, err
	}
	if err := db.AutoMigrate(&resolution.Resolution{}); err != nil {
		return nil, err
	}
	if driver != "postgres" {
		// SQLite 单写者：限制单连接，避免并发写事务触发 database is locked
		sqlDB, err := db.DB()
		if err != nil {
			return nil, err
		}
		sqlDB.SetMaxOpenConns(1)
	}
	return db, nil
}

// OpenDB 按环境变量（DB_DRIVER / DATABASE_URL / DB_SQLITE_DSN）打开数据库。
func OpenDB() (*gorm.DB, error) {
	if os.Getenv("DB_DRIVER") == "postgres" {
		return Open("postgres", os.Getenv("DATABASE_URL"))
	}
	dsn := os.Getenv("DB_SQLITE_DSN")
	if dsn == "" {
		// data/ 目录存放本地 SQLite 文件库（.gitignore 忽略），与 Docker 挂载路径 /data 对齐
		dsn = "data/qtcloud-delib.db"
	}
	return Open("sqlite", dsn)
}

// BuildMux 组装全部模块并返回路由。
// 全部 resolution 端点要求 Bearer JWT（RS256 公钥验签，与 qtcloud-auth 共享密钥对）。
// JWT_PUBLIC_KEY 为 base64(PEM) 公钥；未配置时启动失败（fail-closed）。
func BuildMux(db *gorm.DB) (*http.ServeMux, error) {
	svc := resolution.NewService(db, resolutiongorm.NewResolutionRepo())

	encoded := os.Getenv("JWT_PUBLIC_KEY")
	if encoded == "" {
		return nil, fmt.Errorf("app: JWT_PUBLIC_KEY 未配置（base64(PEM) 公钥，与 qtcloud-auth 配对）")
	}
	_, verifyKey, err := httpserver.PublicKeyFromEnv(encoded)
	if err != nil {
		return nil, err
	}

	mux := http.NewServeMux()
	auth := httpserver.RequireJWT(verifyKey)
	resolution.NewHandler(svc).Register(mux, auth)
	return mux, nil
}
