# =============================================================================
# CanSpace Deployment
# =============================================================================
#
# Generic deployment targets for static websites hosted on CanSpace.
#
# Expected site layout:
#
#   site/
#     content/
#     config/
#     public/
#
# Configuration should be supplied via environment variables or a local
# .env file that is not committed to git.
#
# Required:
#   CANSPACE_HOST
#   CANSPACE_USER
#   CANSPACE_PASSWORD
#
# Optional:
#   CANSPACE_PROTOCOL=ftp
#   CANSPACE_PORT=921
#   CANSPACE_REMOTE_DIR=.
#   CANSPACE_BUILD_DIR=$(SITE_DIR)/public
#
# CanSpace FTP accounts are often jailed directly into the selected document
# root. In that case, keep CANSPACE_REMOTE_DIR as . so deployment mirrors into
# the FTP account root.

-include .env

CANSPACE_PROTOCOL ?= ftp
CANSPACE_PORT ?= 921
CANSPACE_REMOTE_DIR ?= .
CANSPACE_BUILD_DIR ?= $(SITE_DIR)/public

.PHONY: canspace-check canspace-connect canspace-dry-run canspace-deploy

canspace-check:
	@test -n "$(CANSPACE_HOST)" || (echo "CANSPACE_HOST is not set" && exit 1)
	@test -n "$(CANSPACE_USER)" || (echo "CANSPACE_USER is not set" && exit 1)
	@test -n "$(CANSPACE_PASSWORD)" || (echo "CANSPACE_PASSWORD is not set" && exit 1)
	@test -d "$(CANSPACE_BUILD_DIR)" || (echo "$(CANSPACE_BUILD_DIR) does not exist" && exit 1)
	@command -v lftp >/dev/null 2>&1 || (echo "lftp is not installed; run: brew install lftp" && exit 1)

canspace-connect: canspace-check
	lftp -d -u "$(CANSPACE_USER),$(CANSPACE_PASSWORD)" -p "$(CANSPACE_PORT)" "$(CANSPACE_PROTOCOL)://$(CANSPACE_HOST)" -e "\
		set dns:order inet; \
		set net:max-retries 1; \
		set net:timeout 20; \
		set net:reconnect-interval-base 5; \
		set ftp:passive-mode yes; \
		set ftp:ssl-allow yes; \
		pwd; \
		ls; \
		bye"

canspace-dry-run: canspace-check
	lftp -u "$(CANSPACE_USER),$(CANSPACE_PASSWORD)" -p "$(CANSPACE_PORT)" "$(CANSPACE_PROTOCOL)://$(CANSPACE_HOST)" -e "\
		set dns:order inet; \
		set net:max-retries 1; \
		set net:timeout 20; \
		set net:reconnect-interval-base 5; \
		set ftp:passive-mode yes; \
		set ftp:ssl-allow yes; \
		mirror -R --dry-run --delete --verbose $(CANSPACE_BUILD_DIR)/ $(CANSPACE_REMOTE_DIR)/; \
		bye"

canspace-deploy: canspace-check
	lftp -u "$(CANSPACE_USER),$(CANSPACE_PASSWORD)" -p "$(CANSPACE_PORT)" "$(CANSPACE_PROTOCOL)://$(CANSPACE_HOST)" -e "\
		set dns:order inet; \
		set net:max-retries 1; \
		set net:timeout 20; \
		set net:reconnect-interval-base 5; \
		set ftp:passive-mode yes; \
		set ftp:ssl-allow yes; \
		mirror -R --delete --verbose $(CANSPACE_BUILD_DIR)/ $(CANSPACE_REMOTE_DIR)/; \
		bye"