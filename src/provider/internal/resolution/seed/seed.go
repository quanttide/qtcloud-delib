// Package seed 决议种子数据导入：从云端 GitHub（raw）拉取 profile 决议标本写入数据库。
//
// 数据来源：data/profile 子模块的 resolutions/*.json（云端仓库
// github.com/quanttide/quanttide-profile-of-deliberation-management）。
// 通过云端拉取而非本地子模块路径，避免运行时依赖子模块 checkout 状态。
package seed

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"gorm.io/gorm"

	delib "github.com/quanttide/quanttide-delib-toolkit/packages/go/pkg"

	"github.com/quanttide/qtcloud-delib-provider/internal/resolution"
	resolutiongorm "github.com/quanttide/qtcloud-delib-provider/internal/resolution/gorm"
)

// 默认数据源（云端 GitHub）。
const (
	DefaultAPIURL     = "https://api.github.com/repos/quanttide/quanttide-profile-of-deliberation-management/contents/resolutions"
	DefaultRawBaseURL = "https://raw.githubusercontent.com/quanttide/quanttide-profile-of-deliberation-management/main/resolutions"
)

// Import 拉取并导入决议标本（幂等：按 name 跳过已存在），返回导入数量。
func Import(ctx context.Context, db *gorm.DB, apiURL, rawBaseURL string) (int, error) {
	names, err := listResolutionFiles(ctx, apiURL)
	if err != nil {
		return 0, err
	}

	repo := resolutiongorm.NewResolutionRepo()
	client := &http.Client{Timeout: 30 * time.Second}
	imported := 0
	for _, name := range names {
		if err := ctx.Err(); err != nil {
			return imported, err
		}
		raw, err := fetch(ctx, client, rawBaseURL+"/"+name)
		if err != nil {
			return imported, fmt.Errorf("fetch %s: %w", name, err)
		}
		var tkit delib.Resolution
		if err := json.Unmarshal(raw, &tkit); err != nil {
			return imported, fmt.Errorf("parse %s: %w", name, err)
		}
		res := resolution.Resolution{
			ID: tkit.ID, Name: tkit.Name, Title: tkit.Title,
			Content: tkit.Content, Category: tkit.Category,
		}
		if res.Name == "" {
			return imported, fmt.Errorf("specimen %s missing name", name)
		}
		if _, err := repo.GetByName(db, res.Name); err == nil {
			continue // 已存在，跳过（幂等）
		} else if err != gorm.ErrRecordNotFound {
			return imported, fmt.Errorf("check %s: %w", name, err)
		}
		if err := repo.Create(db, &res); err != nil {
			return imported, fmt.Errorf("create %s: %w", name, err)
		}
		imported++
	}
	return imported, nil
}

// listResolutionFiles 经 GitHub contents API 列出决议目录下的 JSON 标本文件名。
func listResolutionFiles(ctx context.Context, apiURL string) ([]string, error) {
	client := &http.Client{Timeout: 30 * time.Second}
	body, err := fetch(ctx, client, apiURL)
	if err != nil {
		return nil, fmt.Errorf("list resolutions: %w", err)
	}
	var entries []struct {
		Name string `json:"name"`
	}
	if err := json.Unmarshal(body, &entries); err != nil {
		return nil, fmt.Errorf("decode contents API: %w", err)
	}
	var names []string
	for _, e := range entries {
		if strings.HasSuffix(e.Name, ".json") {
			names = append(names, e.Name)
		}
	}
	if len(names) == 0 {
		return nil, fmt.Errorf("no resolution specimens found at %s", apiURL)
	}
	return names, nil
}

// fetch GET 拉取并返回响应体；非 2xx 报错。
func fetch(ctx context.Context, client *http.Client, url string) ([]byte, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer func() { _ = resp.Body.Close() }()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GET %s: %s", url, resp.Status)
	}
	return io.ReadAll(resp.Body)
}
