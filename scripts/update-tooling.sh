#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/update-tooling.sh v0.1.1
#
# Overwrites tooling/mk/* with the new version.

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <core-tooling version tag, e.g. v0.1.1>" >&2
  exit 2
fi

if [[ ! -d "tooling/mk" ]]; then
  echo "❌ tooling/mk not found. Run install-tooling.sh first." >&2
  exit 2
fi

exec ./scripts/install-tooling.sh "$VERSION"
