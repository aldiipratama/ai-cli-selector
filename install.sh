#!/bin/bash
#
# This script handles the installation of the ai-select tool.
# It downloads the necessary files from the GitHub repository and sets up
# a global command for the user.
#

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
GITHUB_USER="aldiipratama"
GITHUB_REPO="ai-cli-selector"
GITHUB_BRANCH="main"

# The local installation directory
INSTALL_DIR="$HOME/.local/share/ai-cli-selector"
# The directory for the executable command
BIN_DIR="$HOME/.local/bin"
# The name of the global command
CMD_NAME="ai-select"

# The base URL for raw file access
REPO_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"

# --- Helper Functions for Output ---
# Force output to /dev/tty to ensure it's visible during `curl | sh`
echo_step() { echo -e "\033[0;34m\n➤ $1\033[0m" >/dev/tty; }
echo_info() { echo -e "\033[0;90m  $1\033[0m" >/dev/tty; }
echo_success() { echo -e "\033[0;32m✓ $1\033[0m" >/dev/tty; }
echo_error() { echo -e "\033[0;31m✗ $1\033[0m" >/dev/tty; }
echo_warn() { echo -e "\033[0;33m⚠️ $1\033[0m" >/dev/tty; }

# --- Main Installation Logic ---
main() {
	echo_step "Starting installation of ai-select..."

	# 1. Create all necessary directories
	echo_info "Creating installation directories..."
	mkdir -p "$INSTALL_DIR/data"
	mkdir -p "$INSTALL_DIR/logs"
	mkdir -p "$INSTALL_DIR/cache"
	mkdir -p "$BIN_DIR"
	echo_success "Directories created at $INSTALL_DIR"

	# 2. Copy the script files from the local project directory (for testing)
	echo_info "Copying script files from local project directory..."

	if cp "ai-select.sh" "$INSTALL_DIR/ai-select.sh"; then
		echo_info "Copied ai-select.sh"
	else
		echo_error "Failed to copy ai-select.sh."
		exit 1
	fi

	if cp "data/ai-metadata.conf" "$INSTALL_DIR/data/ai-metadata.conf"; then
		echo_info "Copied ai-metadata.conf"
	else
		echo_error "Failed to copy ai-metadata.conf."
		exit 1

	fi

	echo_success "Files copied."

	# 3. Make the main script executable
	echo_info "Setting execute permissions..."
	chmod +x "$INSTALL_DIR/ai-select.sh"
	echo_success "Permissions set."

	# 4. Create the symbolic link to make the command global
	echo_info "Creating global command '$CMD_NAME' நான"
	ln -sf "$INSTALL_DIR/ai-select.sh" "$BIN_DIR/$CMD_NAME"
	echo_success "Symlink created at $BIN_DIR/$CMD_NAME"

	# 5. Final instructions
	echo_step "Installation Complete!"
	echo_success "You can now run '$CMD_NAME' from anywhere in your terminal."

	# Check if BIN_DIR is in the user's PATH
	case ":$PATH:" in
	*":$BIN_DIR:"*)
		# It's in the PATH, all good.
		;;
	*)
		# It's not in the PATH, give instructions
		echo_warn "The directory '$BIN_DIR' is not in your PATH."
		echo_info "Please add the following line to your shell profile (e.g., ~/.bashrc, ~/.zshrc):"
		echo_info "  export PATH=\"$HOME/.local/bin:$PATH\""
		echo_info "Then, restart your terminal or run 'source ~/.bashrc' (or equivalent)."
		;;
	esac
}

# --- Run the script ---
main
