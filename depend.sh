#!/usr/bin/env bash
set -e

# depend.sh - Auto-detect OS & Arch, clean up old Neovim installations, and install latest Neovim

echo "==> Detecting system architecture and operating system..."

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux)
        case "$ARCH" in
            x86_64|amd64)   ASSET_NAME="nvim-linux-x86_64.tar.gz" ;;
            aarch64|arm64)  ASSET_NAME="nvim-linux-arm64.tar.gz" ;;
            *)
                echo "Error: Unsupported Linux architecture: $ARCH" >&2
                exit 1
                ;;
        esac
        DIR_NAME="${ASSET_NAME%.tar.gz}"
        ;;
    Darwin)
        case "$ARCH" in
            x86_64)         ASSET_NAME="nvim-macos-x86_64.tar.gz" ;;
            arm64|aarch64)  ASSET_NAME="nvim-macos-arm64.tar.gz" ;;
            *)
                echo "Error: Unsupported macOS architecture: $ARCH" >&2
                exit 1
                ;;
        esac
        DIR_NAME="${ASSET_NAME%.tar.gz}"
        ;;
    *)
        echo "Error: Unsupported operating system: $OS" >&2
        exit 1
        ;;
esac

DOWNLOAD_URL="https://github.com/neovim/neovim/releases/latest/download/${ASSET_NAME}"
INSTALL_DIR="$HOME/.local/opt"
BIN_DIR="$HOME/.local/bin"

echo "==> OS: $OS | Arch: $ARCH"

# --- Cleanup Phase ---
echo "==> Cleaning up previous Neovim installations..."

# 1. Clean up old user-level installs in ~/.local/opt & ~/.local/bin
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"/nvim-* 2>/dev/null || true
fi
rm -f "$BIN_DIR/nvim" 2>/dev/null || true

# Helper to check if non-interactive sudo is available
can_sudo() {
    sudo -n true 2>/dev/null
}

# 2. Check for apt/snap/brew system packages
if command -v dpkg >/dev/null 2>&1 && dpkg -l neovim 2>/dev/null | grep -q "^ii"; then
    echo "    Found old apt package 'neovim'."
    if can_sudo; then
        sudo apt-get remove -y neovim neovim-runtime >/dev/null 2>&1 || true
        echo "    Removed old apt package 'neovim'."
    else
        echo "    (Note: Run 'sudo apt remove neovim' to clean up old apt package)."
    fi
fi

if command -v snap >/dev/null 2>&1 && snap list neovim 2>/dev/null | grep -q "neovim"; then
    echo "    Found old snap package 'neovim'."
    if can_sudo; then
        sudo snap remove neovim >/dev/null 2>&1 || true
        echo "    Removed old snap package 'neovim'."
    else
        echo "    (Note: Run 'sudo snap remove neovim' to clean up old snap package)."
    fi
fi

if command -v brew >/dev/null 2>&1 && brew list neovim >/dev/null 2>&1; then
    echo "    Found old Homebrew package 'neovim'. Uninstalling..."
    brew uninstall neovim 2>/dev/null || true
fi

# --- Download & Install Phase ---
echo "==> Fetching latest Neovim from GitHub releases..."
echo "    $DOWNLOAD_URL"

mkdir -p "$INSTALL_DIR" "$BIN_DIR"

tmp_file="$(mktemp)"
curl -fsSL "$DOWNLOAD_URL" -o "$tmp_file"

tar -xzf "$tmp_file" -C "$INSTALL_DIR"
rm -f "$tmp_file"

# Create fresh symlink
ln -sf "${INSTALL_DIR}/${DIR_NAME}/bin/nvim" "${BIN_DIR}/nvim"

echo "==> Successfully installed Neovim!"
"${BIN_DIR}/nvim" --version | head -n 2

# Check active nvim binary path
ACTIVE_NVIM="$(which nvim 2>/dev/null || echo "")"
if [ "$ACTIVE_NVIM" != "${BIN_DIR}/nvim" ]; then
    echo ""
    echo "Notice: Active 'nvim' binary is $ACTIVE_NVIM"
    echo "Ensure $BIN_DIR is placed at the front of your PATH in ~/.zshrc or ~/.bashrc:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
fi
