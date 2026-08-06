// Package app 服务端组装：数据库打开、依赖注入与路由注册。
// cmd/server 与测试共用，保证装配一致。
package app

import (
	"net/http"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

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
func BuildMux(db *gorm.DB) (*http.ServeMux, error) {
	svc := resolution.NewService(db, resolutiongorm.NewResolutionRepo())

	mux := http.NewServeMux()
	resolution.NewHandler(svc).Register(mux)
	return mux, nil
}
