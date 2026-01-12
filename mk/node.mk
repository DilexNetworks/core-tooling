# -----------------------------------------------------------------------------
# node.mk
#
# Optional helper targets for Node-based repos and CDK apps.
# Intended to be vendored and included by repos that need these targets.
# -----------------------------------------------------------------------------

ENABLE_NODE_TARGETS ?= 1

# Directory containing package.json (for library repos, this is usually '.')
PROJECT_DIR ?= .

# CDK application directory (for CDK repos, this is usually 'infra')
CDK_DIR ?= infra

# Tooling defaults
NPM ?= npm
NPX ?= npx

# Allow callers to pass additional args, e.g. `make cdk-deploy CDK_ARGS='--all'`
CDK_ARGS ?=

# Help Order
HELP_ORDER_help-node ?= 20
HELP_TARGETS += help-node

ifeq ($(ENABLE_NODE_TARGETS),1)

# -----------------------------------------------------------------------------
# Namespaced Node targets
#
# These are safe to include alongside other language/tooling mk files.
# -----------------------------------------------------------------------------

.PHONY: node-install node-ci node-build node-test node-lint node-clean help-node
node-install:
	@cd $(PROJECT_DIR) && $(NPM) install

node-ci:
	@cd $(PROJECT_DIR) && $(NPM) ci

node-build:
	@cd $(PROJECT_DIR) && $(NPM) run build

node-test:
	@cd $(PROJECT_DIR) && $(NPM) test

node-lint:
	@cd $(PROJECT_DIR) && $(NPM) run lint

node-clean:
	@cd $(PROJECT_DIR) && $(NPM) run clean

help-node:
	@echo "Node.js / CDK targets (include mk/node.mk):"
	@echo "  make node-install       # npm install"
	@echo "  make node-ci            # npm ci"
	@echo "  make node-build         # npm run build"
	@echo "  make node-test          # npm test"
	@echo "  make node-lint          # npm run lint"
	@echo "  make node-clean         # npm run clean"
	@echo "  make cdk-synth          # cdk synth"
	@echo "  make cdk-diff           # cdk diff"
	@echo "  make cdk-deploy         # cdk deploy"
	@echo "  make cdk-destroy        # cdk destroy"
	@echo ""

# -----------------------------------------------------------------------------
# Optional un-namespaced aliases
#
# Enable these only when you are sure there are no target name collisions
# (e.g., the repo is Node-only).
# -----------------------------------------------------------------------------

ENABLE_NODE_ALIASES ?= 0

ifeq ($(ENABLE_NODE_ALIASES),1)

.PHONY: install ci build test lint clean
install: node-install

ci: node-ci

build: node-build

test: node-test

lint: node-lint

clean: node-clean

endif

# -----------------------------------------------------------------------------
# CDK helpers (already namespaced)
# -----------------------------------------------------------------------------

.PHONY: cdk-synth cdk-diff cdk-deploy cdk-destroy
cdk-synth:
	@cd $(CDK_DIR) && $(NPX) cdk synth $(CDK_ARGS)

cdk-diff:
	@cd $(CDK_DIR) && $(NPX) cdk diff $(CDK_ARGS)

cdk-deploy:
	@cd $(CDK_DIR) && $(NPX) cdk deploy $(CDK_ARGS)

cdk-destroy:
	@cd $(CDK_DIR) && $(NPX) cdk destroy $(CDK_ARGS)

endif