# core-tooling/Makefile
# Dogfood the shared tooling inside this repo.

SITE_DIR ?= .
BRANCH ?= main
TAG_PREFIX ?= v

# core-tooling is not a Hugo module; no module/* tags by default.
RELEASE_MODULE_TAGS ?= 0

# Use the canonical version file name
VERSION_FILE ?= VERSION
BUMPVER_FILE ?= .bumpversion.cfg

# Include the tooling Make fragments from THIS repo (not vendored).
include mk/core.mk
include mk/doctor.mk
include mk/git.mk
include mk/node.mk
include mk/python.mk
include mk/release.mk
include mk/smoke.mk
include mk/help.mk

