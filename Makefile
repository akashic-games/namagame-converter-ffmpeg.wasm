all: dev

MT_FLAGS := -sUSE_PTHREADS -pthread

# コンテナ内の `make -j` 並列度を制御（BuildKit/Rancher Desktop が落ちる場合は 1 へ）
# 例: MAKE_JOBS=1 make prd
MAKE_JOBS ?= 1

# `docker buildx build --platform` を外部から指定したい場合に使う。
# 未指定なら `--platform` 自体を付けない（= buildx のデフォルトに任せる）。
# 例: DOCKER_PLATFORM=linux/amd64 make prd
DOCKER_PLATFORM ?=

# buildx 用の platform 引数（DOCKER_PLATFORM が空なら空文字）
PLATFORM_ARG := $(if $(strip $(DOCKER_PLATFORM)),--platform=$(DOCKER_PLATFORM),)

DEV_ARGS := --progress=plain

DEV_CFLAGS := --profiling
DEV_MT_CFLAGS := $(DEV_CFLAGS) $(MT_FLAGS)
PROD_CFLAGS := -O3 -msimd128
PROD_MT_CFLAGS := $(PROD_CFLAGS) $(MT_FLAGS)

clean:
	rm -rf ./packages/core$(PKG_SUFFIX)/dist

.PHONY: build
build:
	make clean PKG_SUFFIX="$(PKG_SUFFIX)"
	EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
	EXTRA_LDFLAGS="$(EXTRA_LDFLAGS)" \
	FFMPEG_ST="$(FFMPEG_ST)" \
	FFMPEG_MT="$(FFMPEG_MT)" \
		docker buildx build \
			$(PLATFORM_ARG) \
			--build-arg EXTRA_CFLAGS \
			--build-arg EXTRA_LDFLAGS \
			--build-arg FFMPEG_MT \
			--build-arg FFMPEG_ST \
			--build-arg MAKE_JOBS=$(MAKE_JOBS) \
			-o ./packages/core$(PKG_SUFFIX) \
			$(EXTRA_ARGS) \
			.

build-st:
	make build \
		FFMPEG_ST=yes

build-mt:
	make build \
		PKG_SUFFIX=-mt \
		FFMPEG_MT=yes

dev:
	make build-st EXTRA_CFLAGS="$(DEV_CFLAGS)" EXTRA_ARGS="$(DEV_ARGS)"

dev-mt:
	make build-mt EXTRA_CFLAGS="$(DEV_MT_CFLAGS)" EXTRA_ARGS="$(DEV_ARGS)"

prd:
	make build-st EXTRA_CFLAGS="$(PROD_CFLAGS)"

prd-mt:
	make build-mt EXTRA_CFLAGS="$(PROD_MT_CFLAGS)"
