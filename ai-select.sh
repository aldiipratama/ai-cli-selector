#!/bin/bash

# ==============================================================================
# AI-CLI Selector & Installer v1.0
#
# A versatile, production-ready script to select, run, install, and update AI-CLI tools.
# ==============================================================================

# --- Configuration & Global Variables ---
VERSION="1.0"
GITHUB_USER="aldiipratama"
GITHUB_REPO="ai-cli-selector"
GITHUB_BRANCH="main"

# SCRIPT_DIR is made dynamic to handle symlinks from the global command (e.g., ai-select)
if [[ -L "${BASH_SOURCE[0]}" ]]; then
	SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
	SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
else
	SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
fi

CONFIG_FILE="$SCRIPT_DIR/data/ai-metadata.conf"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/session_$(date +%Y%m%d_%H%M%S).log"

declare -a AI_LIST
declare -a AI_TO_INSTALL
declare -a SUCCESSFUL_INSTALLS
declare -a FAILED_INSTALLS

# ==============================================================================
# Module: Logging & User Output
# ==============================================================================
_log_file() { echo "[${1}] $(date '+%Y-%m-%d %H:%M:%S') - ${2}" >>"$LOG_FILE"; }
log_info() { _log_file "INFO" "$1"; }
log_warn() { _log_file "WARN" "$1"; }
log_error() { _log_file "ERROR" "$1"; }
echo_step() { echo -e "\033[0;34m\n➤ $1\033[0m"; }
echo_info() { echo -e "\033[0;90m  $1\033[0m"; }
echo_success() { echo -e "\033[0;32m✓ $1\033[0m"; }
echo_warn() { echo -e "\033[0;33m⚠️ $1\033[0m"; }
echo_error() { echo -e "\033[0;31m✗ $1\033[0m"; }

# ==============================================================================
# Module: Environment Detection & Dependency Management
# ==============================================================================
detect_os() {
	log_info "Detecting OS..."

	OS_TYPE_RAW=$(uname -s)

	case "$OS_TYPE_RAW" in
	Linux*)
		OS_TYPE="linux"
		;;
	Darwin*)
		OS_TYPE="macos"
		;;
	*)
		OS_TYPE="unknown"
		;;
	esac

	log_info "OS detected: $OS_TYPE"
}
detect_package_managers() {
	log_info "Detecting package managers..."

	DETECTED_PKGS=""

	if command -v pacman &>/dev/null; then
		DETECTED_PKGS+="pacman "
	fi

	if command -v apt-get &>/dev/null; then
		DETECTED_PKGS+="apt "
	fi

	if command -v dnf &>/dev/null; then
		DETECTED_PKGS+="dnf "
	fi

	if command -v brew &>/dev/null; then
		DETECTED_PKGS+="brew "
	fi

	if command -v paru &>/dev/null; then
		DETECTED_PKGS+="paru "
	fi

	if command -v yay &>/dev/null; then
		DETECTED_PKGS+="yay "
	fi

	if command -v npm &>/dev/null; then
		DETECTED_PKGS+="npm "
	fi

	if command -v pip &>/dev/null || command -v pip3 &>/dev/null; then
		DETECTED_PKGS+="pip "
	fi

	if command -v cargo &>/dev/null; then
		DETECTED_PKGS+="cargo "
	fi

	PKG_MANAGERS=$(echo "$DETECTED_PKGS" | sed 's/ *$//')
	log_info "Package managers detected: $PKG_MANAGERS"
}
install_packages() {
	local packages_to_install=("$@")

	if [[ ${#packages_to_install[@]} -eq 0 ]]; then
		return 0
	fi

	echo_info "Attempting to install: ${packages_to_install[*]}"
	log_info "Attempting to install packages: ${packages_to_install[*]}"

	if [[ "$PKG_MANAGERS" == *"pacman"* ]]; then
		sudo pacman -S --noconfirm --needed "${packages_to_install[@]}"
	elif [[ "$PKG_MANAGERS" == *"apt"* ]]; then
		sudo apt-get update && sudo apt-get install -y "${packages_to_install[@]}"
	elif [[ "$PKG_MANAGERS" == *"brew"* ]]; then
		brew install "${packages_to_install[@]}"
	elif [[ "$PKG_MANAGERS" == *"dnf"* ]]; then
		sudo dnf install -y "${packages_to_install[@]}"
	else
		echo_error "Cannot automatically install dependencies."
		return 1
	fi

	echo_success "Package installation finished."
}
check_installer_dependencies() {
	echo_step "Checking core dependencies..."
	log_info "Checking core dependencies..."

	local missing_deps=()

	if ! command -v curl &>/dev/null; then
		missing_deps+=("curl")
	fi

	if ! command -v git &>/dev/null; then
		missing_deps+=("git")
	fi

	if [[ ${#missing_deps[@]} -gt 0 ]]; then
		echo_warn "Some core dependencies were not found: ${missing_deps[*]}"
		install_packages "${missing_deps[@]}"
	else
		echo_success "Core dependencies are satisfied."
	fi
}

# ==============================================================================
# Module: Config Parser
# ==============================================================================
parse_config() {
	log_info "Parsing config file: $CONFIG_FILE"

	AI_LIST=()

	if [[ ! -f "$CONFIG_FILE" ]]; then
		echo_error "Configuration file '$CONFIG_FILE' not found!"
		exit 1
	fi

	local current_section=""

	while IFS= read -r line || [[ -n "$line" ]]; do
		line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

		if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
			continue
		fi

		if [[ "$line" =~ ^\[.*\]$ ]]; then
			current_section=$(echo "$line" | sed 's/\[//;s/\]//')

			AI_LIST+=("$current_section")

			declare -gA "$current_section"
		elif [[ "$line" =~ .*=.* ]] && [[ -n "$current_section" ]]; then
			local key

			key=$(echo "$line" | cut -d'=' -f1)

			local value

			value=$(echo "$line" | cut -d'=' -f2-)

			declare -n arr_ref="$current_section"

			arr_ref["$key"]="$value"
		fi
	done <"$CONFIG_FILE"

	log_info "Parsed ${#AI_LIST[@]} AI-CLIs from config."
}

# ==============================================================================
# Module: UI Functions
# ==============================================================================
show_text_menu() {
	echo_step "Please select AI-CLIs to install:"
	echo_info "Using text menu because interactive UI is unavailable/failed."
	echo_info "Enter numbers (space-separated), then press [Enter]."

	local options=($@)

	for i in "${!options[@]}"; do
		local ai_name="${options[$i]}"

		local desc_ref="${ai_name}[description]"

		printf "  %2d) %-15s - %s\n" "$((i + 1))" "$ai_name" "${!desc_ref}"
	done

	echo "  99) EXIT"
	read -rp "Your choice: " -a selections

	for choice in "${selections[@]}"; do
		if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
			echo_warn "Invalid input '$choice' ignored."
			continue
		fi

		if [[ "$choice" -eq 99 ]]; then
			echo_warn "Exiting as requested by user."
			exit 0
		fi

		if [[ "$choice" -ge 1 && "$choice" -le ${#options[@]} ]]; then
			AI_TO_INSTALL+=("${options[$((choice - 1))]}")
		else
			echo_warn "Invalid choice '$choice' ignored."
		fi
	done
}
show_gum_menu() {
	echo_step "Please select AI-CLIs to install:"
	echo_info "Use [Space] to select, [Arrows] to navigate, [Enter] to confirm."

	local options=($@)
	local gum_options=()

	for ai_name in "${options[@]}"; do
		local desc_ref="${ai_name}[description]"
		gum_options+=("$(printf "%-15s - %s" "$ai_name" "${!desc_ref}")")
	done

	local selections
	selections=$(gum choose --no-limit --height 15 --cursor "➤ " --selected-prefix "✓ " --unselected-prefix "○ " "${gum_options[@]}")

	if [[ $? -ne 0 ]]; then
		return 1
	fi

	if [[ -z "$selections" ]]; then
		AI_TO_INSTALL=()
		return 0
	fi

	local selected_names
	read -r -d '' selected_names <<<"$(echo "$selections" | awk '{print $1}')"
	mapfile -t AI_TO_INSTALL < <(echo "$selected_names")
	return 0
}
show_selection_menu() {
	local use_gum=false

	if command -v gum &>/dev/null; then
		use_gum=true
	else
		echo_warn "Utility 'gum' for modern UI not found."
		echo "Select menu type: [1] Try to install 'gum', [2] Continue with simple text menu"
		read -p "Your choice [1-2]: " menu_choice

		if [[ "$menu_choice" == "1" ]]; then
			echo_step "Attempting to install 'gum'"
			install_packages "gum"

			if command -v gum &>/dev/null; then
				echo_success "'gum' installed successfully."
				use_gum=true
			else
				echo_error "Installation of 'gum' failed."
			fi
		fi
	fi

	if [[ "$use_gum" == true ]]; then
		show_gum_menu "${AI_LIST[@]}" || {
			echo_error "Interactive 'gum' menu failed."
			echo_info "Falling back to text menu..."
			show_text_menu "${AI_LIST[@]}"
		}
	else
		echo_info "Continuing with text menu."
		show_text_menu "${AI_LIST[@]}"
	fi

	AI_TO_INSTALL=($(echo "${AI_TO_INSTALL[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

	if [[ ${#AI_TO_INSTALL[@]} -gt 0 ]]; then
		echo_success "Selected for installation: ${AI_TO_INSTALL[*]}"
	else
		echo_warn "No valid AI-CLIs were selected."
	fi
}

# ==============================================================================
# Module: Installer
# ==============================================================================
install_via_pacman() {
	sudo pacman -S --noconfirm --needed "$1"
}

install_via_aur() {
	if command -v paru &>/dev/null; then
		paru -S --noconfirm --needed "$1"
	elif command -v yay &>/dev/null; then
		yay -S --noconfirm --needed "$1"
	else
		return 1
	fi
}

install_via_apt() {
	sudo apt-get install -y "$1"
}

install_via_brew() {
	brew install "$1"
}

install_via_npm() {
	npm install -g "$1"
}

install_via_pip() {
	if command -v pipx &>/dev/null; then
		pipx install "$1"
	elif python3 -c 'import sys; exit(0 if sys.base_prefix != sys.prefix else 1)'; then
		pip install "$1"
	else
		python3 -m pip install --user "$1"
	fi
}

install_via_manual() {
	local ai_name="$1"
	local install_cmd="$2"

	echo_warn "Installation for '$ai_name' requires running a manual script from the internet."
	echo -e "Command: \033[0;33m${install_cmd}\033[0m"
	read -p "Continue? [y/N]: " -n 1 -r
	echo

	if [[ "$REPLY" =~ ^[Yy]$ ]]; then
		bash -c "${install_cmd}"
	else
		return 1
	fi
}

process_installations() {
	if [[ ${#AI_TO_INSTALL[@]} -eq 0 ]]; then
		return
	fi

	echo_step "Starting installation process for: ${AI_TO_INSTALL[*]}"

	for ai_name in "${AI_TO_INSTALL[@]}"; do
		echo_step "Processing: $ai_name"

		local preferred_source_ref="${ai_name}[preferred_source]"
		local alt_sources_ref="${ai_name}[alt_sources]"
		local methods_to_try=()
		methods_to_try+=("${!preferred_source_ref}")
		local alt_sources_str="${!alt_sources_ref}"

		if [[ -n "$alt_sources_str" ]]; then
			IFS='|' read -ra alt_methods <<<"$alt_sources_str"
			for method in "${alt_methods[@]}"; do
				methods_to_try+=("$method")
			done
		fi

		local install_succeeded=false
		local successful_method=""

		for method in "${methods_to_try[@]}"; do
			if [[ -z "$method" ]]; then
				continue
			fi

			echo_info "Attempting installation method: '$method'..."

			local install_failed=0
			local pkg_name_ref
			local pkg_name
			local install_cmd_ref
			local install_cmd

			(case "$method" in
				pacman)
					pkg_name_ref="${ai_name}[arch_pkg]"
					pkg_name="${!pkg_name_ref}"
					[[ -n "$pkg_name" ]] && install_via_pacman "$pkg_name"
					;;
				aur)
					pkg_name_ref="${ai_name}[aur_pkg]"
					pkg_name="${!pkg_name_ref}"
					[[ -n "$pkg_name" ]] && install_via_aur "$pkg_name"
					;;
				apt)
					pkg_name_ref="${ai_name}[debian_pkg]"
					pkg_name="${!pkg_name_ref}"
					[[ -n "$pkg_name" ]] && install_via_apt "$pkg_name"
					;;
				brew)
					pkg_name_ref="${ai_name}[brew_pkg]"
					pkg_name="${!pkg_name_ref}"
					[[ -n "$pkg_name" ]] && install_via_brew "$pkg_name"
					;;
				npm)
					pkg_name_ref="${ai_name}[npm_pkg]"
					pkg_name="${!pkg_name_ref}"
					[[ -n "$pkg_name" ]] && install_via_npm "$pkg_name"
					;;
				pip | pipx)
					pkg_name_ref="${ai_name}[pip_pkg]"
					pkg_name="${!pkg_name_ref}"
					[[ -n "$pkg_name" ]] && install_via_pip "$pkg_name"
					;;
				cargo)
					pkg_name_ref="${ai_name}[cargo_pkg]"
					pkg_name="${!pkg_name_ref}"
					[[ -n "$pkg_name" ]] && cargo install "$pkg_name"
					;;
				manual)
					install_cmd_ref="${ai_name}[manual_install]"
					install_cmd="${!install_cmd_ref}"
					[[ -n "$install_cmd" ]] && install_via_manual "$ai_name" "$install_cmd"
					;;
				*)
					echo_warn "Installation method '$method' is not supported."
					exit 1
					;;
				esac) || install_failed=1

			if [[ $install_failed -eq 0 ]]; then
				local test_cmd_ref="${ai_name}[test_command]"
				local test_cmd="${!test_cmd_ref}"

				if [[ -n "$test_cmd" ]] && (eval "$test_cmd" &>/dev/null); then
					install_succeeded=true
					successful_method="$method"
					break
				elif [[ -z "$test_cmd" ]]; then
					install_succeeded=true
					successful_method="$method"
					break
				else
					echo_error "Verification of '$ai_name' failed after installing via '$method'."
				fi
			else
				echo_warn "Method '$method' failed for '$ai_name'."
			fi
		done

		if [[ "$install_succeeded" == true ]]; then
			echo_success "Successfully installed $ai_name."
			SUCCESSFUL_INSTALLS+=("$ai_name (via $successful_method)")
		else
			echo_error "All installation methods for '$ai_name' failed."
			FAILED_INSTALLS+=("$ai_name")
		fi
	done
}

# ==============================================================================
# Module: Report & Execution Modes
# ==============================================================================
print_summary_report() {
	echo_step "Installation Summary Report"

	if [[ ${#SUCCESSFUL_INSTALLS[@]} -gt 0 ]]; then
		echo_success "Successfully Installed:"
		for item in "${SUCCESSFUL_INSTALLS[@]}"; do
			echo_info "  - $item"
		done
	fi

	if [[ ${#FAILED_INSTALLS[@]} -gt 0 ]]; then
		echo_error "Failed to Install:"

		for item in "${FAILED_INSTALLS[@]}"; do
			echo_info "  - $item"
		done

		echo
		echo_warn "For failed items, please consider opening an issue on GitHub:"
		echo_info ">> https://github.com/paldi123/ai-cli-installer/issues"
	fi

	if [[ ${#FAILED_INSTALLS[@]} -eq 0 && ${#SUCCESSFUL_INSTALLS[@]} -gt 0 ]]; then
		echo_success "All selected AI tools were installed successfully!"
	fi
}

run_install_mode() {
	log_info "--- Running in Install Mode ---"
	echo_step "Starting Install Mode..."
	detect_os
	detect_package_managers
	echo_info "System: $OS_TYPE | Package Managers: $PKG_MANAGERS"
	check_installer_dependencies
	show_selection_menu
	process_installations
	print_summary_report
}

run_launcher_mode() {
	log_info "--- Running in Launcher Mode ---"

	if ! command -v gum &>/dev/null; then
		echo_error "Required command 'gum' is not installed."
		echo_info "Please run 'ai-select install' to install dependencies."
		exit 1
	fi

	echo_info "Detecting installed tools..."

	local gum_options=()

	for ai_name in "${AI_LIST[@]}"; do
		local test_cmd_ref="${ai_name}[test_command]"
		local test_cmd="${!test_cmd_ref}"

		if [[ -n "$test_cmd" ]] && (eval "$test_cmd" &>/dev/null); then
			local desc_ref="${ai_name}[description]"
			gum_options+=("$(printf "%-15s - %s" "$ai_name" "${!desc_ref}")")
		fi
	done

	if [[ ${#gum_options[@]} -eq 0 ]]; then
		echo_warn "No installed AI-CLIs were detected."
		echo_info "Run 'ai-select install' to install tools."
		exit 0
	fi

	echo_step "Select an AI-CLI to run:"

	local selection
	selection=$(gum choose --height 15 --cursor "➤ " "${gum_options[@]}")

	if [[ -z "$selection" ]]; then
		echo_warn "Nothing selected. Exiting."
		exit 0
	fi

	local selected_ai_name
	selected_ai_name=$(echo "$selection" | awk '{print $1}')
	local command_ref="${selected_ai_name}[command]"
	local command_to_run="${!command_ref}"

	if [[ -z "$command_to_run" ]]; then
		echo_error "Could not find the command for '$selected_ai_name'. Check your configuration."
		exit 1
	fi

	shift
	local extra_args=($@)

	echo_step "Executing: $command_to_run ${extra_args[*]}"
	log_info "Executing: $command_to_run ${extra_args[*]}"
	exec "$command_to_run" "${extra_args[@]}"
}

run_update_mode() {
	log_info "--- Running in Update Mode ---"
	echo_step "Checking for updates..."

	local REPO_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"
	local temp_script
	temp_script=$(mktemp)

	if ! curl -fsSL "${REPO_URL}/ai-select.sh" -o "$temp_script"; then
		echo_error "Failed to download the latest script. Please check your connection."
		rm "$temp_script"
		exit 1
	fi

	local remote_version
	remote_version=$(grep -m 1 '^VERSION=' "$temp_script" | cut -d'"' -f2)

	if [[ -z "$remote_version" ]]; then
		echo_error "Could not determine remote version. Update aborted."
		rm "$temp_script"
		exit 1
	fi

	if [[ "$VERSION" == "$remote_version" ]]; then
		echo_success "You are already on the latest version ($VERSION)."
		rm "$temp_script"
		exit 0
	fi

	echo_info "New version available: $remote_version. Updating from $VERSION..."
	local temp_config
	temp_config=$(mktemp)

	if ! curl -fsSL "${REPO_URL}/data/ai-metadata.conf" -o "$temp_config"; then
		echo_error "Failed to download the latest configuration. Update aborted."
		rm "$temp_script" "$temp_config"
		exit 1
	fi

	echo_info "Applying updates..."
	mv "$temp_script" "$SCRIPT_DIR/ai-select.sh"
	mv "$temp_config" "$CONFIG_FILE"
	chmod +x "$SCRIPT_DIR/ai-select.sh"
	echo_success "Update complete! You are now on version $remote_version."
}

# ==============================================================================
# Main Dispatcher
# ==============================================================================
main() {
	mkdir -p "$LOG_DIR" && touch "$LOG_FILE"
	log_info "--- Starting AI-CLI Selector & Installer v${VERSION} ---"

	case "$1" in
	update | --update | -u)
		run_update_mode
		exit 0
		;;
	esac

	parse_config
	case "$1" in
	install | --install | -i)
		shift
		run_install_mode "$@"
		;;
	*)
		run_launcher_mode "$@"
		;;
	esac
}

# --- Run Script ---
main "$@"
