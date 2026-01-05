check_branch:
	@b=$$(git rev-parse --abbrev-ref HEAD); \
	[ "$$b" = "$(BRANCH)" ] || { echo "❌ Must run from $(BRANCH), currently $$b"; exit 2; }

check_clean:
	@git diff --quiet && git diff --cached --quiet || { echo "❌ Working tree is not clean"; exit 2; }

check_up_to_date:
	@git fetch origin $(BRANCH) >/dev/null 2>&1; \
	l=$$(git rev-parse HEAD); r=$$(git rev-parse origin/$(BRANCH)); \
	[ "$$l" = "$$r" ] || { echo "❌ $(BRANCH) is not up to date with origin/$(BRANCH)"; exit 2; }

check_gh:
	@gh auth status >/dev/null 2>&1 || { echo "❌ GitHub CLI not authenticated (run gh auth login)"; exit 2; }
