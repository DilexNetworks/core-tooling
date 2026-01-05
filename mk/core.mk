SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c

# Reduce noise from nested make invocations
MAKEFLAGS += --no-print-directory

# Common defaults (override in consuming repo Makefile if needed)
BRANCH ?= main
TAG_PREFIX ?= v
VALID_RELEASE_TYPES ?= patch minor major

# Container runtime (OCI-compatible). Override per repo if needed.
OCI_RUNTIME ?= docker

# Repo layout: default to "." for module repos; site repos set SITE_DIR=site
SITE_DIR ?= .
DATA_DIR ?= $(SITE_DIR)/data

# Versioning
VERSION_FILE ?= VERSION
BUMPVER_FILE ?= .bumpversion.cfg
RELEASE ?=
