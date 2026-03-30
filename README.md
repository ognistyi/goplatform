# goplatform

CLI tool that prints the current platform name and architecture.

```
 >>> Platform: darwin/amd64
```

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/ognistyi/goplatform/main/install.sh | sh
```

## How it works

### Release pipeline

```
git commit → git push → git tag vX.Y.Z → git push origin vX.Y.Z
                                                    |
                                        .github/workflows/release.yml
                                        triggered on: push tags: v*
                                                    |
                                        goreleaser/goreleaser-action
                                        reads .goreleaser.yml
                                                    |
                                        go build x5:
                                          linux/amd64
                                          linux/arm64
                                          darwin/amd64
                                          darwin/arm64
                                          windows/amd64
                                                    |
                                        GitHub Release created
                                        with binaries + checksums.txt
```

**Key points:**

- Only a tag push triggers the build — regular commits to `main` do nothing.
- GoReleaser sets `CGO_ENABLED=0`, so binaries are fully static with no external dependencies.
- Artifact names follow the pattern `goplatform_<version>_<os>_<arch>` (no `v` prefix in the filename, e.g. `goplatform_1.0.0_linux_amd64`).
- `GITHUB_TOKEN` is injected automatically by GitHub Actions — no manual secrets needed.

### Installer (`install.sh`)

```
curl … | sh
    |
    ├── detect OS   (uname -s → linux / darwin / windows)
    ├── detect ARCH (uname -m → amd64 / arm64)
    |
    ├── GET https://api.github.com/repos/ognistyi/goplatform/releases/latest
    │       → extracts tag_name (e.g. v1.2.0)
    |
    ├── strips leading 'v' → 1.2.0
    │   builds filename:  goplatform_1.2.0_darwin_amd64
    │   builds URL:       github.com/…/releases/download/v1.2.0/goplatform_1.2.0_darwin_amd64
    |
    ├── curl download → /tmp/goplatform
    ├── chmod +x
    └── mv → /usr/local/bin/goplatform  (sudo if needed)
```

**Why `v` is stripped:** GoReleaser uses the full tag (`v1.2.0`) in the download URL path but omits the `v` in artifact filenames. The installer handles this discrepancy explicitly.

## Releasing a new version

```bash
git add .
git commit -m "feat: describe the change"
git push origin main
git tag v1.2.3
git push origin v1.2.3
```

Watch the build:

```bash
gh run watch --repo ognistyi/goplatform
```

## Local build

```bash
go build -o goplatform .
./goplatform
```

## Cross-compile manually

```bash
GOOS=linux GOARCH=arm64 go build -o goplatform-linux-arm64 .
```
