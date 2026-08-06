# syntax=docker/dockerfile:1

# ---- 构建阶段 ----
# mattn/go-sqlite3 依赖 CGO，需要 gcc/musl-dev 工具链；产物为动态链接 musl 的二进制
#
# 构建上下文约定：仓库根（域根布局：apps/qtcloud-delib + packages/quanttide-delib-toolkit），
# 使 go.mod 的 replace 相对路径（../../../../packages/...）成立。
# 用法：docker build -f src/provider/Dockerfile -t qtcloud-delib-provider:latest .
FROM golang:1.26-alpine AS build

RUN apk add --no-cache gcc musl-dev

WORKDIR /src

# 依赖代理：默认国内可达的 goproxy.cn（proxy.golang.org 在部分网络环境不可达）
# 覆盖：docker build --build-arg GOPROXY=https://proxy.golang.org,direct .
ARG GOPROXY=https://goproxy.cn,direct
ENV GOPROXY=${GOPROXY}

# 先拷贝模块文件与 replace 依赖（工具库），利用构建缓存
COPY apps/qtcloud-delib/src/provider/go.mod apps/qtcloud-delib/src/provider/go.sum apps/qtcloud-delib/src/provider/
COPY packages/quanttide-delib-toolkit/packages/go/ packages/quanttide-delib-toolkit/packages/go/
RUN cd apps/qtcloud-delib/src/provider && go mod download

COPY . .
RUN cd apps/qtcloud-delib/src/provider && CGO_ENABLED=1 go build -trimpath -ldflags="-s -w" -o /out/provider-server ./cmd/server

# ---- 运行阶段 ----
# 与构建阶段同为 musl libc，二进制可直接运行
FROM alpine:3.20

RUN addgroup -S app && adduser -S -G app app
COPY --from=build /out/provider-server /usr/local/bin/provider-server

USER app
EXPOSE 8080

ENTRYPOINT ["provider-server"]
CMD ["-addr", ":8080"]
