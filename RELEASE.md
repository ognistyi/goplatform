# Release Guide

## Project Workflow

```
code change → commit → git tag vX.Y.Z → git push origin vX.Y.Z
                                                      |
                                          GitHub Actions triggered
                                                      |
                                          GoReleaser builds 5 binaries:
                                            linux/amd64, linux/arm64
                                            darwin/amd64, darwin/arm64
                                            windows/amd64
                                                      |
                                          GitHub Release created with
                                          binaries + checksums.txt
```

## Releasing a New Version

```bash
git tag v1.2.3
git push origin v1.2.3
```

That's it. The workflow at `.github/workflows/release.yml` fires on any `v*` tag push.

## Versioning

Follow [semver](https://semver.org): `vMAJOR.MINOR.PATCH`

- PATCH — bug fixes
- MINOR — new features, backwards-compatible
- MAJOR — breaking changes

## Installer

```sh
curl -fsSL https://raw.githubusercontent.com/ognistyi/goplatform/main/install.sh | sh
```

The script detects the current OS and architecture, downloads the matching binary from the latest GitHub Release, and installs it to `/usr/local/bin/goplatform`.

## Local Build

```bash
go build -o goplatform .
./goplatform
```
