doctor:
	@command -v git >/dev/null 2>&1 || { echo "❌ git not found"; exit 2; }
	@command -v gh >/dev/null 2>&1 || { echo "❌ gh not found"; exit 2; }
	@command -v bump2version >/dev/null 2>&1 || { echo "❌ bump2version not found"; exit 2; }

doctor-hugo:
	@command -v docker >/dev/null 2>&1 || { echo "❌ docker not found"; exit 2; }
	@docker info >/dev/null 2>&1 || { echo "❌ docker not running"; exit 2; }

.PHONY: doctor doctor-hugo
