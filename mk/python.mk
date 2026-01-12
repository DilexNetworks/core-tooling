# -----------------------------------------------------------------------------
# python.mk
#
# Optional helper targets for Python-based repos.
# Targets are namespaced by default to avoid collisions when multiple language
# mk files are included in the same repository.
# -----------------------------------------------------------------------------

ENABLE_PYTHON_TARGETS ?= 1

# Directory containing Python project files (requirements.txt, pyproject.toml, etc.)
PY_PROJECT_DIR ?= .

# Virtual environment directory
PY_VENV_DIR ?= .venv

# Python executables (inside the venv)
PYTHON ?= python3
PY_VENV_PY ?= $(PY_VENV_DIR)/bin/python
PY_VENV_PIP ?= $(PY_VENV_DIR)/bin/pip

# Test and lint runners (override per repo)
PY_TEST_CMD ?= -m pytest
PY_LINT_CMD ?= -m ruff check .
PY_FMT_CMD ?= -m ruff format .

# Install mode (choose one):
# - requirements: install from requirements.txt if present
# - editable: install the project in editable mode (pip install -e .)
PY_INSTALL_MODE ?= requirements

# Optional extra pip args (e.g. "--upgrade")
PIP_ARGS ?=

# Help Order
HELP_ORDER_help-python ?= 30
HELP_TARGETS += help-python

ifeq ($(ENABLE_PYTHON_TARGETS),1)

# -----------------------------------------------------------------------------
# Namespaced Python targets
# -----------------------------------------------------------------------------

.PHONY: py-venv py-install py-install-editable py-test py-lint py-fmt py-clean help-python

py-venv:
	@cd $(PY_PROJECT_DIR) && $(PYTHON) -m venv $(PY_VENV_DIR)

py-install: py-venv
	@cd $(PY_PROJECT_DIR) && \
	if [ "$(PY_INSTALL_MODE)" = "editable" ]; then \
		$(PY_VENV_PIP) install $(PIP_ARGS) -e .; \
	else \
		if [ -f requirements.txt ]; then \
			$(PY_VENV_PIP) install $(PIP_ARGS) -r requirements.txt; \
		else \
			echo "❌ requirements.txt not found (set PY_INSTALL_MODE=editable or add requirements.txt)"; \
			exit 2; \
		fi; \
	fi

# Convenience target if a repo always wants editable installs
py-install-editable:
	@$(MAKE) py-install PY_INSTALL_MODE=editable

py-test: py-venv
	@cd $(PY_PROJECT_DIR) && $(PY_VENV_PY) $(PY_TEST_CMD)

py-lint: py-venv
	@cd $(PY_PROJECT_DIR) && $(PY_VENV_PY) $(PY_LINT_CMD)

py-fmt: py-venv
	@cd $(PY_PROJECT_DIR) && $(PY_VENV_PY) $(PY_FMT_CMD)

py-clean:
	@cd $(PY_PROJECT_DIR) && rm -rf $(PY_VENV_DIR) .pytest_cache .ruff_cache

help-python:
	@echo "Python targets (include mk/python.mk):"
	@echo "  make py-venv             # create virtualenv"
	@echo "  make py-install          # install dependencies"
	@echo "  make py-install-editable # pip install -e ."
	@echo "  make py-test             # run tests"
	@echo "  make py-lint             # run linters"
	@echo "  make py-fmt              # format code"
	@echo "  make py-clean            # remove venv + caches"
	@echo ""

# -----------------------------------------------------------------------------
# Optional un-namespaced aliases
#
# Enable these only when you are sure there are no target name collisions.
# -----------------------------------------------------------------------------

ENABLE_PYTHON_ALIASES ?= 0

ifeq ($(ENABLE_PYTHON_ALIASES),1)

.PHONY: venv install test lint fmt clean
venv: py-venv

install: py-install

test: py-test

lint: py-lint

fmt: py-fmt

clean: py-clean

endif

endif
