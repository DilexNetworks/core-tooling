.DEFAULT_GOAL := help

# Optional list of help contribution targets provided by other mk files.
# Example contributions: help-node, help-python, help-smoke
HELP_TARGETS ?=

# Assign an optional numeric sort key per help target. If not set, defaults to 50.
# Example:
#   HELP_ORDER_help-node := 20
#   HELP_ORDER_help-python := 30
#
# Ordering is computed lazily so that mk files included after help.mk can still
# append to HELP_TARGETS.

define _help_key
$(if $(HELP_ORDER_$(1)),$(HELP_ORDER_$(1)),50):$(1)
endef

HELP_TARGETS_KEYED = $(foreach t,$(HELP_TARGETS),$(call _help_key,$(t)))
HELP_TARGETS_SORTED = $(sort $(HELP_TARGETS_KEYED))
HELP_TARGETS_ORDERED = $(foreach kt,$(HELP_TARGETS_SORTED),$(word 2,$(subst :, ,$(kt))))

.PHONY: help help-core

help: help-core $(HELP_TARGETS_ORDERED)

help-core:
	@echo ""
	@echo "Core targets:"
	@echo "  make help               # show this help"
	@echo "  make doctor             # verify required tooling"
	@echo "  make clean              # clean build artifacts (if supported)"
	@echo ""
	@echo "Build targets (repo-specific / opt-in):"
	@echo "  make build              # build the project"
	@echo "  make dev                # run dev server (if supported)"
	@echo ""
	@echo "Release (explicit opt-in required):"
	@echo "  make release RELEASE=patch|minor|major"
	@echo ""
	@echo "Optional (Hugo / container-based):"
	@echo "  make doctor-hugo        # verify container runtime + Hugo"
	@echo ""

