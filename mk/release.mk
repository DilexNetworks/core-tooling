# Resolve the templates directory relative to this mk file.
# Works both in core-tooling itself (mk/../templates) and when vendored (tooling/mk/../templates).
_THIS_MK_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
CORE_TOOLING_TEMPLATES_DIR ?= $(abspath $(_THIS_MK_DIR)/../templates)

# Where Hugo (or other consumers) can read version metadata
VERSION_JSON ?= $(DATA_DIR)/version.json

# Optional: create a second tag for Hugo module consumers ("module/vX.Y.Z")
# Enable per repo with: RELEASE_MODULE_TAGS=1
RELEASE_MODULE_TAGS ?= 0

require_release:
	@if [ -z "$(RELEASE)" ]; then \
	  echo "❌ Refusing to run release without explicit confirmation."; \
	  echo "   Use: make release RELEASE=patch|minor|major"; \
	  exit 2; \
	fi
	@if ! echo "$(VALID_RELEASE_TYPES)" | grep -qw "$(RELEASE)"; then \
	  echo "❌ Invalid RELEASE type: '$(RELEASE)'"; \
	  echo "   Valid values: patch, minor, major"; \
	  exit 2; \
	fi

check_version:
	@V=$$(tr -d ' \t\n\r' < $(VERSION_FILE) 2>/dev/null || true); \
	if [ -z "$$V" ]; then \
	  echo "❌ $(VERSION_FILE) is empty or missing"; exit 2; \
	fi; \
	if ! echo "$$V" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$'; then \
	  echo "❌ $(VERSION_FILE) must contain SemVer like 1.2.3 (got: '$$V')"; exit 2; \
	fi

check_tags:
	@CUR=$$(tr -d ' \t\n\r' < $(VERSION_FILE) 2>/dev/null || true); \
	IFS='.' read -r MA MI PA <<< "$$CUR"; \
	case "$(RELEASE)" in \
	  major) MA=$$((10#$$MA + 1)); MI=0; PA=0 ;; \
	  minor) MI=$$((10#$$MI + 1)); PA=0 ;; \
	  patch) PA=$$((10#$$PA + 1)) ;; \
	  *) echo "❌ Invalid RELEASE type: '$(RELEASE)'"; exit 2 ;; \
	esac; \
	NEXT="$$MA.$$MI.$$PA"; \
	ROOT="$(TAG_PREFIX)$$NEXT"; \
	git rev-parse "$$ROOT" >/dev/null 2>&1 && { echo "❌ Tag $$ROOT already exists"; exit 2; } || true; \
	if [ "$(RELEASE_MODULE_TAGS)" = "1" ]; then \
	  MOD="module/$(TAG_PREFIX)$$NEXT"; \
	  git rev-parse "$$MOD" >/dev/null 2>&1 && { echo "❌ Tag $$MOD already exists"; exit 2; } || true; \
	fi

preflight: check_version check_branch check_clean check_up_to_date check_tags check_gh

bump_version:
	@echo "→ Updating $(BRANCH) and bumping version ($(RELEASE))"
	@git checkout $(BRANCH)
	@git pull origin $(BRANCH)
	@bump2version $(RELEASE)

version_json:
	@VTXT=$$(tr -d ' \t\n\r' < $(VERSION_FILE) 2>/dev/null || true); \
	[ -n "$$VTXT" ] || { echo "❌ $(VERSION_FILE) is empty or missing"; exit 2; }; \
	TAG="$(TAG_PREFIX)$$VTXT"; \
	DATE=$$(git log -1 --format=%cs HEAD); \
	mkdir -p "$(DATA_DIR)"; \
	echo "{ \"tag\": \"$$TAG\", \"date\": \"$$DATE\" }" > "$(VERSION_JSON)"; \
	echo "Wrote $(VERSION_JSON) -> $$TAG ($$DATE)"

init-versioning:
	@if [ -f "$(VERSION_FILE)" ]; then \
	  echo "ℹ️  $(VERSION_FILE) already exists"; \
	else \
	  if [ -f "$(CORE_TOOLING_TEMPLATES_DIR)/VERSION" ]; then \
	    echo "→ Creating $(VERSION_FILE) from templates"; \
	    cp "$(CORE_TOOLING_TEMPLATES_DIR)/VERSION" "$(VERSION_FILE)"; \
	  else \
	    echo "→ Creating $(VERSION_FILE)"; \
	    echo "0.1.0" > "$(VERSION_FILE)"; \
	  fi; \
	fi
	@if [ -f "$(BUMPVER_FILE)" ]; then \
	  echo "ℹ️  $(BUMPVER_FILE) already exists"; \
	else \
	  if [ -f "$(CORE_TOOLING_TEMPLATES_DIR)/bumpversion.cfg" ]; then \
	    echo "→ Creating $(BUMPVER_FILE) from templates"; \
	    cp "$(CORE_TOOLING_TEMPLATES_DIR)/bumpversion.cfg" "$(BUMPVER_FILE)"; \
	  else \
	    echo "→ Creating $(BUMPVER_FILE)"; \
	    printf '%s\n' \
	      '[bumpversion]' \
	      'current_version = 0.1.0' \
	      'commit = False' \
	      'tag = False' \
	      '' \
	      "[bumpversion:file:$(VERSION_FILE)]" \
	      > "$(BUMPVER_FILE)"; \
	  fi; \
	fi

commit_and_push:
	@echo "→ Committing version bump"
	@git add $(VERSION_FILE) $(BUMPVER_FILE) $(VERSION_JSON)
	@VERSION_NEW=$$(tr -d ' \t\n\r' < $(VERSION_FILE)); \
	git commit -m "chore(release): $(TAG_PREFIX)$$VERSION_NEW"
	@echo "→ Pushing $(BRANCH)"
	@git push origin $(BRANCH)

create_tag_release:
	@VTXT=$$(tr -d ' \t\n\r' < $(VERSION_FILE) 2>/dev/null || true); \
	[ -n "$$VTXT" ] || { echo "❌ $(VERSION_FILE) is empty or missing"; exit 2; }; \
	ROOT_TAG="$(TAG_PREFIX)$$VTXT"; \
	echo "→ Tagging $$ROOT_TAG"; \
	git tag "$$ROOT_TAG"; \
	git push origin "$$ROOT_TAG"; \
	if [ "$(RELEASE_MODULE_TAGS)" = "1" ]; then \
	  MODULE_TAG="module/$(TAG_PREFIX)$$VTXT"; \
	  echo "→ Tagging $$MODULE_TAG"; \
	  git tag "$$MODULE_TAG"; \
	  git push origin "$$MODULE_TAG"; \
	fi; \
	echo "→ Creating GitHub release $$ROOT_TAG"; \
	gh release create "$$ROOT_TAG" \
		--title "Release $$ROOT_TAG" \
		--generate-notes

release: require_release preflight bump_version version_json commit_and_push create_tag_release

release-patch:
	$(MAKE) RELEASE=patch release

release-minor:
	$(MAKE) RELEASE=minor release

release-major:
	$(MAKE) RELEASE=major release
