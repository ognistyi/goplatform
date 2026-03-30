#!/bin/sh
set -e

REPO="ognistyi/goplatform"
BINARY="goplatform"
INSTALL_DIR="/usr/local/bin"

detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case "$OS" in
        linux)   ;;
        darwin)  ;;
        mingw*|msys*|cygwin*) OS="windows" ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac

    case "$ARCH" in
        x86_64)         ARCH="amd64" ;;
        aarch64|arm64)  ARCH="arm64" ;;
        *)
            echo "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
}

fetch_latest_version() {
    VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' \
        | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -z "$VERSION" ]; then
        echo "Failed to fetch latest version"
        exit 1
    fi
}

install_binary() {
    EXT=""
    [ "$OS" = "windows" ] && EXT=".exe"

    # GoReleaser strips the leading 'v' from the tag in artifact names
    VERSION_NUM="${VERSION#v}"
    FILENAME="${BINARY}_${VERSION_NUM}_${OS}_${ARCH}${EXT}"
    URL="https://github.com/${REPO}/releases/download/${VERSION}/${FILENAME}"

    TMP=$(mktemp -d)
    DEST="${TMP}/${BINARY}${EXT}"

    echo "Downloading ${FILENAME}..."
    curl -fsSL "$URL" -o "$DEST"
    chmod +x "$DEST"

    if [ -w "$INSTALL_DIR" ]; then
        mv "$DEST" "${INSTALL_DIR}/${BINARY}${EXT}"
    else
        sudo mv "$DEST" "${INSTALL_DIR}/${BINARY}${EXT}"
    fi

    rm -rf "$TMP"
}

main() {
    detect_platform
    fetch_latest_version
    install_binary
    echo "Installed ${BINARY} ${VERSION} to ${INSTALL_DIR}/${BINARY}"
    "${INSTALL_DIR}/${BINARY}"
}

main
