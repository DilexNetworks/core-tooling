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
#
# Credentials should be stored in ~/.netrc, not in .env:
#
#   machine eos.canspace.ca
#     login your-ftp-user@example.com
#     password your-password
#
# Make sure ~/.netrc is only readable by your user:
#
#   chmod 600 ~/.netrc
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
	@test -f "$(HOME)/.netrc" || (echo "$(HOME)/.netrc does not exist" && exit 1)
	@test "$$(stat -f %Lp $(HOME)/.netrc)" = "600" || (echo "$(HOME)/.netrc must be chmod 600" && exit 1)
	@test -d "$(CANSPACE_BUILD_DIR)" || (echo "$(CANSPACE_BUILD_DIR) does not exist" && exit 1)
	@command -v lftp >/dev/null 2>&1 || (echo "lftp is not installed; run: brew install lftp" && exit 1)

canspace-connect: canspace-check
	lftp -d -e "\
		set netrc:enabled yes; \
		set netrc:file $(HOME)/.netrc; \
		set dns:order inet; \
		set net:max-retries 1; \
		set net:timeout 20; \
		set net:reconnect-interval-base 5; \
		set ftp:passive-mode yes; \
		set ftp:ssl-allow yes; \
		open -p $(CANSPACE_PORT) $(CANSPACE_PROTOCOL)://$(CANSPACE_HOST); \
		pwd; \
		ls; \
		bye"

canspace-dry-run: canspace-check
	lftp -e "\
		set netrc:enabled yes; \
		set netrc:file $(HOME)/.netrc; \
		set dns:order inet; \
		set net:max-retries 1; \
		set net:timeout 20; \
		set net:reconnect-interval-base 5; \
		set ftp:passive-mode yes; \
		set ftp:ssl-allow yes; \
		open -p $(CANSPACE_PORT) $(CANSPACE_PROTOCOL)://$(CANSPACE_HOST); \
		mirror -R --dry-run --delete --verbose $(CANSPACE_BUILD_DIR)/ $(CANSPACE_REMOTE_DIR)/; \
		bye"

canspace-deploy: canspace-check
	lftp -e "\
		set netrc:enabled yes; \
		set netrc:file $(HOME)/.netrc; \
		set dns:order inet; \
		set net:max-retries 1; \
		set net:timeout 20; \
		set net:reconnect-interval-base 5; \
		set ftp:passive-mode yes; \
		set ftp:ssl-allow yes; \
		open -p $(CANSPACE_PORT) $(CANSPACE_PROTOCOL)://$(CANSPACE_HOST); \
		mirror -R --delete --verbose $(CANSPACE_BUILD_DIR)/ $(CANSPACE_REMOTE_DIR)/; \
		bye"