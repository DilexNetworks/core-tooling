# core-tooling

Foundational Makefile tooling shared across the **core** ecosystem.

This repository provides a small, boring, reusable set of Makefile includes
that standardize:

- versioning and releases
- GitHub tagging and releases
- optional Hugo build workflows (container-based)
- environment validation ("doctor")

The goal is **consistency without magic**: repositories vendor these files at a
known version, commit them, and update explicitly when desired.

---

## What this repo is

- A source of truth for shared Makefile logic
- Designed to be *vendored*, not used as a submodule
- Safe to update incrementally and review via normal git diffs

## What this repo is not

- A site generator
- A framework
- A runtime dependency

---

## Directory layout

```text
mk/
  core.mk              # shared defaults and variables
  help.mk              # `make help` output and default target
  doctor.mk            # environment validation
  git.mk               # git safety checks
  release.mk           # versioning, tagging, GitHub releases
  container-hugo.mk    # OCI/container-based Hugo helpers (optional)

templates/
  VERSION               # canonical version file
  bumpversion.cfg       # canonical bump2version config

scripts/
  install-tooling.sh    # vendor tooling into another repo
  update-tooling.sh     # update vendored tooling to a new version
```

---

## Usage in consuming repositories

Tooling is vendored into a repo under `tooling/mk/`.

A minimal root `Makefile` typically looks like:

```make
SITE_DIR ?= site        # use '.' for module/library repos

include tooling/mk/core.mk
include tooling/mk/help.mk
include tooling/mk/doctor.mk
include tooling/mk/git.mk
include tooling/mk/release.mk

# Optional (Hugo sites only, container-based)
include tooling/mk/container-hugo.mk
```

---

## Versioning and releases

This repo uses:

- `VERSION` for the canonical version
- `bump2version` for controlled version bumps
- annotated git tags (`vX.Y.Z`)
- GitHub Releases generated via the `gh` CLI

Bootstrap versioning once per repo:

```bash
make init-versioning
git add VERSION .bumpversion.cfg
git commit -m "chore: initialize versioning"
```

Release a new version:

```bash
make release RELEASE=patch
make release RELEASE=minor
make release RELEASE=major
```

---

## Container runtime abstraction

Container-based helpers are written against a generic OCI-style runtime,
not Docker-specific behavior.

By default:

```make
OCI_RUNTIME ?= docker
```

All container commands are routed through `$(OCI_RUNTIME)`, making it
possible to switch to alternatives such as Podman, Colima, or nerdctl
without changing Makefile logic.

Repositories that do not use containerized workflows should simply omit
`container-hugo.mk` entirely.

---

## Design principles

- Explicit over clever
- Vendored over implicit
- Boring over magical
- Easy to replace or rewrite

This repo is intentionally small and opinionated.

---

## License

MIT