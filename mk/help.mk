.DEFAULT_GOAL := help

help:
	@echo ""
	@echo "Core targets:"
	@echo "  make help             # show this help"
	@echo "  make doctor           # verify required tooling"
	@echo "  make clean            # clean build artifacts"
	@echo ""
	@echo "Build targets (repo-specific):"
	@echo "  make build            # build the project"
	@echo "  make dev              # run dev server (if supported)"
	@echo ""
	@echo "Release (explicit opt-in required):"
	@echo "  make release RELEASE=patch|minor|major"
	@echo ""
	@echo "Optional (Hugo / container-based):"
	@echo "  make doctor-hugo      # verify container runtime + Hugo"
	@echo ""
