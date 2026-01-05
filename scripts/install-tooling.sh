#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/install-tooling.sh v0.1.0
#
# Expects to run from the ROOT of the consuming repo.

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <core-tooling version tag, e.g. v0.1.0>" >&2
  exit 2
fi

REPO="DilexNetworks/core-tooling"   # change org if needed
DEST_DIR="tooling/mk"
VERSION_FILE="tooling/CORE_TOOLING_VERSION"
TEMPLATES_DEST_DIR="tooling/templates"

mkdir -p "$DEST_DIR"
mkdir -p "$TEMPLATES_DEST_DIR"

echo "→ Fetching core-tooling $VERSION"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Prefer gh if available (handles private orgs nicely), otherwise curl
if command -v gh >/dev/null 2>&1; then
  gh repo clone "$REPO" "$tmp/core-tooling" -- --depth 1 --branch "$VERSION"
else
  # Public-only fallback: download tarball
  # (If private, install gh and auth instead.)
  url="https://github.com/${REPO}/archive/refs/tags/${VERSION}.tar.gz"
  curl -fsSL "$url" | tar -xz -C "$tmp"
  mv "$tmp"/core-tooling-* "$tmp/core-tooling"
fi

cp -R "$tmp/core-tooling/mk/." "$DEST_DIR/"

if [[ -d "$tmp/core-tooling/templates" ]]; then
  cp -R "$tmp/core-tooling/templates/." "$TEMPLATES_DEST_DIR/"
fi

echo "$VERSION" > "$VERSION_FILE"
echo "✅ Installed core-tooling $VERSION into $DEST_DIR and $TEMPLATES_DEST_DIR"
echo "   Pinned version written to $VERSION_FILE"
