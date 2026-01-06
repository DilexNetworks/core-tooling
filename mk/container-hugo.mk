# -----------------------------
# Containerized Hugo toolchain (OCI runtime)
# -----------------------------
HUGO_IMAGE ?= wyllie/hugo:latest
HUGO_WORKDIR ?= /app

DEV_PORT ?= 1313

UID := $(shell id -u)
GID := $(shell id -g)

CACHE_PREFIX := $(shell basename "$(PWD)")
HUGO_CACHE_VOL ?= $(CACHE_PREFIX)-hugo-cache
GO_MOD_CACHE_VOL ?= $(CACHE_PREFIX)-gomod-cache

HUGO_CACHEDIR ?= /cache/hugo
GOMODCACHE ?= /cache/go/pkg/mod
GOCACHE ?= /cache/go/build

OCI_RUN_ROOT = $(OCI_RUNTIME) run --rm -it \
	-e HUGO_CACHEDIR=$(HUGO_CACHEDIR) \
	-e GOMODCACHE=$(GOMODCACHE) \
	-e GOCACHE=$(GOCACHE) \
	-v "$(HUGO_CACHE_VOL):$(HUGO_CACHEDIR)" \
	-v "$(GO_MOD_CACHE_VOL):/cache/go" \
	-v "$(PWD):$(HUGO_WORKDIR)" \
	-w "$(HUGO_WORKDIR)"

OCI_RUN = $(OCI_RUNTIME) run --rm -it \
	-u $(UID):$(GID) \
	-e HUGO_CACHEDIR=$(HUGO_CACHEDIR) \
	-e GOMODCACHE=$(GOMODCACHE) \
	-e GOCACHE=$(GOCACHE) \
	-v "$(HUGO_CACHE_VOL):$(HUGO_CACHEDIR)" \
	-v "$(GO_MOD_CACHE_VOL):/cache/go" \
	-v "$(PWD):$(HUGO_WORKDIR)" \
	-w "$(HUGO_WORKDIR)"

OCI_RUN_DEV = $(OCI_RUN) -p $(DEV_PORT):1313

HOST_IP := $(shell ipconfig getifaddr en0 2>/dev/null || \
	ipconfig getifaddr en1 2>/dev/null || \
	hostname -I 2>/dev/null | awk '{print $$1}' || \
	echo localhost)

# Default Hugo config args: assumes hugo.toml in SITE_DIR
HUGO_CONFIG_ARGS ?= --config $(SITE_DIR)/config/_default/hugo.toml

# Default baseURL for dev (override if you prefer localhost)
HUGO_BASEURL ?= http://$(HOST_IP):$(DEV_PORT)/

HUGO_SERVER_ARGS ?= -D \
	--disableFastRender --ignoreCache \
	$(HUGO_CONFIG_ARGS) \
	--source $(SITE_DIR) \
	--bind 0.0.0.0 \
	--baseURL=$(HUGO_BASEURL)

cache_ensure:
	@$(OCI_RUNTIME) volume inspect $(HUGO_CACHE_VOL) >/dev/null 2>&1 || $(OCI_RUNTIME) volume create $(HUGO_CACHE_VOL) >/dev/null
	@$(OCI_RUNTIME) volume inspect $(GO_MOD_CACHE_VOL) >/dev/null 2>&1 || $(OCI_RUNTIME) volume create $(GO_MOD_CACHE_VOL) >/dev/null
	@$(OCI_RUN_ROOT) $(HUGO_IMAGE) /bin/bash -lc '\
		mkdir -p "$(HUGO_CACHEDIR)" "$(GOMODCACHE)" "$(GOCACHE)"; \
		chown -R $(UID):$(GID) /cache/go "$(HUGO_CACHEDIR)"'
	@$(OCI_RUN) $(HUGO_IMAGE) /bin/bash -lc '\
		if [ -d "$(GOMODCACHE)" ] && [ -w "$(GOMODCACHE)" ] && [ "$$(ls -A "$(GOMODCACHE)" 2>/dev/null | wc -l | tr -d " ")" -gt 0 ]; then \
			echo "✅ Hugo/Go module cache already populated"; \
		else \
			echo "⬇️  Warming Hugo/Go module cache (first run)"; \
			cd "$(SITE_DIR)" && hugo mod get && hugo mod tidy; \
		fi'

cache_warm:
	@$(OCI_RUN) $(HUGO_IMAGE) /bin/bash -lc 'cd "$(SITE_DIR)" && hugo mod get && hugo mod tidy'

modules_update:
	@$(OCI_RUN) $(HUGO_IMAGE) /bin/bash -lc 'cd "$(SITE_DIR)" && hugo mod get -u && hugo mod tidy'

cache_clear:
	-$(OCI_RUNTIME) volume rm $(HUGO_CACHE_VOL) $(GO_MOD_CACHE_VOL)

versions:
	@$(OCI_RUN) $(HUGO_IMAGE) /bin/bash -lc 'hugo version; echo; sass --version; echo; command -v node >/dev/null 2>&1 && node --version || echo "node: (not installed)"; command -v npm >/dev/null 2>&1 && npm --version || echo "npm: (not installed)"; echo; aws --version'

shell:
	@$(OCI_RUN_DEV) $(HUGO_IMAGE) /bin/bash

dev: cache_ensure clean
	@echo "Using IP: $(HOST_IP)"
	@$(OCI_RUN_DEV) $(HUGO_IMAGE) /bin/bash -lc 'hugo server $(HUGO_SERVER_ARGS)'

build: cache_ensure
	@$(OCI_RUN) $(HUGO_IMAGE) /bin/bash -lc 'hugo --source "$(SITE_DIR)" --minify $(HUGO_CONFIG_ARGS)'

rebuild: cache_ensure clean
	@$(OCI_RUN) $(HUGO_IMAGE) /bin/bash -lc 'hugo --source "$(SITE_DIR)" --gc --cleanDestinationDir $(HUGO_CONFIG_ARGS)'

clean:
	@rm -rf "$(SITE_DIR)/public" "$(SITE_DIR)/resources" "$(SITE_DIR)/.hugo_cache" || true

doctor-hugo:
	@command -v $(OCI_RUNTIME) >/dev/null 2>&1 || { echo "❌ $(OCI_RUNTIME) not found"; exit 2; }
	@if [ "$(OCI_RUNTIME)" = "docker" ]; then \
		docker info >/dev/null 2>&1 || { echo "❌ docker not running"; exit 2; }; \
	elif [ "$(OCI_RUNTIME)" = "podman" ]; then \
		podman info >/dev/null 2>&1 || { echo "❌ podman not running"; exit 2; }; \
	else \
		$(OCI_RUNTIME) info >/dev/null 2>&1 || true; \
	fi
	@$(OCI_RUN) $(HUGO_IMAGE) /bin/bash -lc 'hugo version'
