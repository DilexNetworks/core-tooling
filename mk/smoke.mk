# -----------------------------------------------------------------------------
# smoke.mk
#
# Smoke tests for core-tooling.
# Validates that mk fragments are syntactically valid and targets are callable.
# Uses `make -n` (dry run) to avoid requiring project-specific files.
# -----------------------------------------------------------------------------

ENABLE_SMOKE ?= 1

# Help contribution (ordered after language sections)
HELP_TARGETS += help-smoke
HELP_ORDER_help-smoke ?= 40

ifeq ($(ENABLE_SMOKE),1)

.PHONY: smoke smoke-node smoke-python help-smoke

smoke: smoke-node smoke-python
	@echo "✅ core-tooling smoke tests passed"

smoke-node:
	@echo "→ smoke: node.mk"
	@$(MAKE) --no-print-directory -n -f mk/node.mk node-install ENABLE_NODE_TARGETS=1 ENABLE_NODE_ALIASES=0 PROJECT_DIR=. >/dev/null
	@$(MAKE) --no-print-directory -n -f mk/node.mk cdk-synth ENABLE_NODE_TARGETS=1 CDK_DIR=infra >/dev/null

smoke-python:
	@echo "→ smoke: python.mk"
	@$(MAKE) --no-print-directory -n -f mk/python.mk py-venv ENABLE_PYTHON_TARGETS=1 ENABLE_PYTHON_ALIASES=0 PY_PROJECT_DIR=. >/dev/null
	@$(MAKE) --no-print-directory -n -f mk/python.mk py-test ENABLE_PYTHON_TARGETS=1 PY_PROJECT_DIR=. >/dev/null

help-smoke:
	@echo "Tooling validation:"
	@echo "  make smoke              # run core-tooling smoke tests"
	@echo ""

endif
