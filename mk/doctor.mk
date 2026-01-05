doctor:
	@command -v git >/dev/null 2>&1 || { echo "❌ git not found"; exit 2; }
	@command -v gh >/dev/null 2>&1 || { echo "❌ gh not found"; exit 2; }
	@command -v bump2version >/dev/null 2>&1 || { echo "❌ bump2version not found"; exit 2; }

.PHONY: doctor
