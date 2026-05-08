## [1.0.0-beta.2](https://github.com/equa/equa-base/compare/v1.0.0-beta.1...v1.0.0-beta.2) (2026-05-08)

### Bug Fixes

* build and test image locally before push; tag with semver ([35a8809](https://github.com/equa/equa-base/commit/35a8809d2900ca3296ddd1c802acacda9817e178))
* disable MD041 for CHANGELOG.md (semantic-release omits h1) ([b812184](https://github.com/equa/equa-base/commit/b8121840391425a42b592cfab2b9707b7ea037cd))

## 1.0.0-beta.1 (2026-05-08)

### Features

* bootstrap equa-base with Dockerfile, toolchain tests, composite actions, and release workflow ([d26e997](https://github.com/equa/equa-base/commit/d26e997051914ee5dca5147036653d72b7813924))

### Bug Fixes

* add markdownlint config (relax MD013/MD060) ([655f94e](https://github.com/equa/equa-base/commit/655f94eb8719a1168eb850083b5cd52e85b80522))
* avoid sourcing setvars.sh in smoke test (calls exit) ([77e0f80](https://github.com/equa/equa-base/commit/77e0f80b512524a75569cdf02454d22405aaf4bd))
* correct lychee tarball asset name in Dockerfile ([79ae185](https://github.com/equa/equa-base/commit/79ae1852174231332fffbc2676118d3ae38b17ab))
* remove unknown cspell words (toolname, path) ([d04f3e8](https://github.com/equa/equa-base/commit/d04f3e874516294c6f9576d4a83a4a9177c398f2))
* scope lint globs to root-level md only ([0c7e2e9](https://github.com/equa/equa-base/commit/0c7e2e92b3b4e06d91c7fb76952a127b5b183085))
* update trivy-action to v0.36.0 ([29c9678](https://github.com/equa/equa-base/commit/29c96789fdd0f957726e1af1fda78372dcdb09b5))
* use icpx (not icx) for C++ smoke test compilation ([a6739cc](https://github.com/equa/equa-base/commit/a6739cc73aa6f17c4a6b424f64fe596983db306b))
* use trivy-action@0.35.0 (non-v-prefixed tag) ([285c7f7](https://github.com/equa/equa-base/commit/285c7f7db5b61ec825a4e2b9b4e522d6a1f7d521))
