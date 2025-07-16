#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
print_info() {
    echo -e "\033[34mINFO: $1\033[0m"
}

print_success() {
    echo -e "\033[32mSUCCESS: $1\033[0m"
}

print_warning() {
    echo -e "\033[33mWARNING: $1\033[0m"
}

print_error() {
    echo -e "\033[31mERROR: $1\033[0m" >&2
}

# --- Determine Project Root Directory ---
# This script is expected to be in 'scripts/configure.sh'
# Project root is one level up from the script's directory.
SCRIPT_DIR_CONFIGURE="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT_DIR="$(cd "$SCRIPT_DIR_CONFIGURE/.." &> /dev/null && pwd)"

# --- Backup Function ---
backup_file_or_dir() {
    local item_to_backup="$1"
    if [ -e "$item_to_backup" ] || [ -L "$item_to_backup" ]; then # Check if file or directory exists
        local backup_name="${item_to_backup}.bak_$(date +%Y%m%d_%H%M%S)"
        print_info "Backing up existing $item_to_backup to $backup_name"
        if mv "$item_to_backup" "$backup_name"; then
            print_success "Backup of $item_to_backup successful."
        else
            print_error "Failed to backup $item_to_backup."
            # Decide if you want to exit or continue
            # exit 1
        fi
    fi
}

# --- Distribution Detection (minimal, for package installs if needed) ---
detect_distro_pm() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
        # shellcheck disable=SC2153 # ID_LIKE is from /etc/os-release
        OS_LIKE=$(echo "$ID_LIKE" | tr '[:upper:]' '[:lower:]')

        if [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS_LIKE" == *"debian"* ]]; then
            PACKAGE_MANAGER="apt"
            PYTHON_PIP_PACKAGE="python3-pip"
            PIPX_PACKAGE="pipx"
        elif [[ "$OS" == "fedora" ]]; then
            PACKAGE_MANAGER="dnf"
            PYTHON_PIP_PACKAGE="python3-pip" # python3-pip is usually part of python3-devel or a direct package
            PIPX_PACKAGE="pipx"
        elif [[ "$OS" == "arch" || "$OS_LIKE" == *"arch"* ]]; then
            PACKAGE_MANAGER="pacman"
            PYTHON_PIP_PACKAGE="python-pip"
            PIPX_PACKAGE="pipx"
        else
            PACKAGE_MANAGER=""
            PYTHON_PIP_PACKAGE=""
            PIPX_PACKAGE=""
            print_warning "Unsupported distribution for automatic pip/pipx installation in configure.sh: $OS"
        fi
    else
        PACKAGE_MANAGER=""
        PYTHON_PIP_PACKAGE=""
        PIPX_PACKAGE=""
        print_warning "Cannot determine Linux distribution for pip/pipx installation. /etc/os-release not found."
    fi
}

print_info "Starting configuration script..."
print_info "Project Root: $PROJECT_ROOT_DIR"

# --- GNOME Shell Specific Configuration ---
if [[ "$(echo "${XDG_CURRENT_DESKTOP:-}" | tr '[:upper:]' '[:lower:]')" == *"gnome"* ]]; then
    print_info "GNOME Desktop Environment detected."
    print_warning "GNOME extension management might require this script to be run from within an active GNOME session."
    print_warning "If 'gext' commands fail, ensure you are running this from a terminal within GNOME."

    detect_distro_pm # Detect package manager for pip/pipx

    # Ensure pipx is installed
    if ! command -v pipx &> /dev/null; then
        print_info "pipx command not found. Attempting to install pipx..."
        pipx_installed_by_pm=false
        if [ -n "$PACKAGE_MANAGER" ] && [ -n "$PIPX_PACKAGE" ]; then
            print_info "Attempting to install $PIPX_PACKAGE using $PACKAGE_MANAGER..."
            # shellcheck disable=SC2015 # We want to proceed even if update fails for some reason if install can work
            case "$PACKAGE_MANAGER" in
                apt) sudo apt-get update && sudo apt-get install -y "$PIPX_PACKAGE" || print_warning "Failed to install $PIPX_PACKAGE with apt." ;;
                dnf) sudo dnf install -y "$PIPX_PACKAGE" || print_warning "Failed to install $PIPX_PACKAGE with dnf." ;;
                pacman) sudo pacman -Syu --noconfirm "$PIPX_PACKAGE" || print_warning "Failed to install $PIPX_PACKAGE with pacman." ;;
                *) print_warning "No direct $PACKAGE_MANAGER command for $PIPX_PACKAGE." ;;
            esac
            if command -v pipx &> /dev/null; then
                pipx_installed_by_pm=true
                print_success "$PIPX_PACKAGE installed via $PACKAGE_MANAGER."
            else
                 print_warning "$PIPX_PACKAGE installation via $PACKAGE_MANAGER may have failed or package not found by that name."
            fi
        fi

        if ! $pipx_installed_by_pm ; then
            print_info "pipx not installed via package manager, trying pip method."
            # Ensure python3-pip is installed if pipx wasn't installed by PM
            if ! command -v pip3 &> /dev/null && ! python3 -m pip --version &> /dev/null; then
                print_info "pip3 command not found. Attempting to install $PYTHON_PIP_PACKAGE..."
                if [ -n "$PACKAGE_MANAGER" ] && [ -n "$PYTHON_PIP_PACKAGE" ]; then
                    # shellcheck disable=SC2015
                    case "$PACKAGE_MANAGER" in
                        apt) sudo apt-get update && sudo apt-get install -y "$PYTHON_PIP_PACKAGE" || (print_error "Failed to install $PYTHON_PIP_PACKAGE with apt."; exit 1) ;;
                        dnf) sudo dnf install -y "$PYTHON_PIP_PACKAGE" || (print_error "Failed to install $PYTHON_PIP_PACKAGE with dnf."; exit 1) ;;
                        pacman) sudo pacman -Syu --noconfirm "$PYTHON_PIP_PACKAGE" || (print_error "Failed to install $PYTHON_PIP_PACKAGE with pacman."; exit 1) ;;
                        *) print_error "Cannot install $PYTHON_PIP_PACKAGE. Unknown package manager: $PACKAGE_MANAGER"; exit 1 ;;
                    esac
                    if ! command -v pip3 &> /dev/null && ! python3 -m pip --version &> /dev/null; then
                         print_error "Failed to install $PYTHON_PIP_PACKAGE. Please install it manually."
                         exit 1
                    fi
                    print_success "$PYTHON_PIP_PACKAGE installed."
                else
                    print_error "pip3 is not installed and cannot determine how to install it for your distribution. Please install python3-pip manually."
                    exit 1
                fi
            fi
            print_info "Installing pipx using pip..."
            python3 -m pip install --user pipx
            print_info "Ensuring pipx is in PATH (may require new terminal session or re-login)..."
            # This command typically advises to add ~/.local/bin to PATH
            python3 -m pipx ensurepath

            # Attempt to add ~/.local/bin to PATH for the current session
            if [[ ! ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
                export PATH="$HOME/.local/bin:$PATH"
                print_info "Temporarily added $HOME/.local/bin to PATH for this session."
            fi

            if ! command -v pipx &> /dev/null; then
                 print_error "pipx installation with pip failed or it's not in PATH even after attempting to add it."
                 print_warning "You might need to open a new terminal or re-login for pipx to be available."
                 print_warning "Then re-run this configuration script."
                 # exit 1 # Optionally exit if pipx is critical
            else
                print_success "pipx installed via pip and appears to be in PATH for this session."
            fi
        fi
    fi

    if command -v pipx &> /dev/null; then
        print_info "pipx is available."
        # Install gnome-extensions-cli using pipx
        # Check if gext is already installed by pipx list
        if pipx list --short | grep -q -w "gnome-extensions-cli"; then # -w for whole word match
            print_info "gnome-extensions-cli is already installed via pipx."
        else
            if command -v gext &> /dev/null; then # Check if gext command exists from other source
                 print_info "gext (gnome-extensions-cli) is already available (possibly not via pipx)."
            else
                print_info "Installing gnome-extensions-cli using pipx..."
                if pipx install gnome-extensions-cli --system-site-packages; then
                    print_success "gnome-extensions-cli installed."
                else
                    print_error "Failed to install gnome-extensions-cli with pipx."
                fi
            fi
        fi

        # Install extensions from list.txt
        EXTENSIONS_LIST_FILE="$PROJECT_ROOT_DIR/extensions/list.txt"
        if [ -f "$EXTENSIONS_LIST_FILE" ]; then
            print_info "Installing GNOME extensions from $EXTENSIONS_LIST_FILE..."
            if command -v gext &> /dev/null; then
                while IFS= read -r extension_uuid || [ -n "$extension_uuid" ]; do
                    extension_uuid=$(echo "$extension_uuid" | xargs) # Trim whitespace
                    if [ -n "$extension_uuid" ] && [[ ! "$extension_uuid" =~ ^\s*# ]]; then # Ignore empty lines and comments
                        print_info "Processing extension: $extension_uuid"
                        if gext list --installed | grep -qF "$extension_uuid"; then
                            print_info "Extension $extension_uuid is already installed."
                        else
                            print_info "Installing extension: $extension_uuid"
                            if gext install "$extension_uuid"; then
                                print_success "Extension $extension_uuid installed successfully."
                            else
                                print_error "Failed to install extension $extension_uuid. It might be incompatible or already installed with errors."
                            fi
                        fi
                    fi
                done < "$EXTENSIONS_LIST_FILE"
                # Enable extensions (optional, gext install usually enables them)
                # print_info "Attempting to enable installed extensions..."
                # while IFS= read -r extension_uuid || [ -n "$extension_uuid" ]; do
                #    extension_uuid=$(echo "$extension_uuid" | xargs) # Trim whitespace
                #    if [ -n "$extension_uuid" ] && [[ ! "$extension_uuid" =~ ^\s*# ]]; then
                #        gext enable "$extension_uuid" || print_warning "Could not enable $extension_uuid"
                #    fi
                # done < "$EXTENSIONS_LIST_FILE"
                print_success "Finished processing GNOME extensions list."
            else
                print_error "gext command not found. Cannot install GNOME extensions. Try re-running after ensuring pipx paths are set (new terminal/re-login)."
            fi
        else
            print_warning "Extensions list file not found: $EXTENSIONS_LIST_FILE"
        fi
    else
        print_error "pipx command not found and installation failed. Cannot install gnome-extensions-cli or GNOME extensions."
    fi
else
    print_info "Not a GNOME Desktop Environment (XDG_CURRENT_DESKTOP is '${XDG_CURRENT_DESKTOP:-not set}'). Skipping GNOME specific configurations."
fi

# --- General Configuration Files Deployment ---
print_info "Deploying general configuration files..."

# Zsh
ZSH_CONFIG_SOURCE="$PROJECT_ROOT_DIR/zsh/.zshrc"
ZSH_CONFIG_DEST="$HOME/.zshrc"
if [ -f "$ZSH_CONFIG_SOURCE" ]; then
    print_info "Deploying .zshrc..."
    backup_file_or_dir "$ZSH_CONFIG_DEST"
    cp "$ZSH_CONFIG_SOURCE" "$ZSH_CONFIG_DEST"
    print_success ".zshrc deployed to $ZSH_CONFIG_DEST"
else
    print_warning "Zsh configuration source not found: $ZSH_CONFIG_SOURCE"
fi

# WezTerm
WEZTERM_DIR_SOURCE="$PROJECT_ROOT_DIR/wezterm" # This is a directory
WEZTERM_CONFIG_DIR_DEST_BASE="$HOME/.config" # Wezterm usually goes into .config/wezterm or directly as .wezterm.lua
WEZTERM_CONFIG_DIR_DEST="$HOME/.config/wezterm"
WEZTERM_LUA_SOURCE="$WEZTERM_DIR_SOURCE/wezterm.lua" # Assuming the file is wezterm.lua inside the project's wezterm dir

# Option 1: Copy wezterm.lua file if it exists
if [ -f "$WEZTERM_LUA_SOURCE" ]; then
    print_info "Deploying wezterm.lua..."
    mkdir -p "$WEZTERM_CONFIG_DIR_DEST"
    backup_file_or_dir "$WEZTERM_CONFIG_DIR_DEST/wezterm.lua"
    cp "$WEZTERM_LUA_SOURCE" "$WEZTERM_CONFIG_DIR_DEST/wezterm.lua"
    print_success "WezTerm configuration (wezterm.lua) deployed to $WEZTERM_CONFIG_DIR_DEST/wezterm.lua"
# Option 2: If the project's 'wezterm' directory itself is meant to be the config (e.g. with lua files and subdirs)
elif [ -d "$WEZTERM_DIR_SOURCE" ] && [ -n "$(ls -A $WEZTERM_DIR_SOURCE)" ]; then # If source dir exists and is not empty
    print_info "Deploying entire WezTerm configuration directory from $WEZTERM_DIR_SOURCE..."
    # Ensure base .config dir exists
    mkdir -p "$WEZTERM_CONFIG_DIR_DEST_BASE"
    backup_file_or_dir "$WEZTERM_CONFIG_DIR_DEST" # Backup existing ~/.config/wezterm directory
    # Copy the contents of project's wezterm dir to ~/.config/wezterm
    # Using rsync is safer for merging or if the dest dir already has other files.
    # cp -R "$WEZTERM_DIR_SOURCE" "$WEZTERM_CONFIG_DIR_DEST_BASE" # This would copy the 'wezterm' folder itself into .config
    # To copy contents of $WEZTERM_DIR_SOURCE into $WEZTERM_CONFIG_DIR_DEST:
    mkdir -p "$WEZTERM_CONFIG_DIR_DEST" # Ensure target wezterm dir exists
    if cp -aT "$WEZTERM_DIR_SOURCE/" "$WEZTERM_CONFIG_DIR_DEST/"; then # -a for archive, -T to treat source as normal if it's a dir
         print_success "WezTerm configuration directory deployed to $WEZTERM_CONFIG_DIR_DEST"
    else
        print_error "Failed to deploy WezTerm configuration directory."
    fi
else
    print_warning "WezTerm configuration source ($WEZTERM_LUA_SOURCE or non-empty $WEZTERM_DIR_SOURCE) not found. Skipping WezTerm deployment."
    print_info "If you have WezTerm config, place it as 'wezterm.lua' in the 'wezterm' folder of your project, or fill the 'wezterm' folder with your full WezTerm config structure."
fi

# Change default shell to Zsh (if zsh is installed)
if command -v zsh &> /dev/null; then
    CURRENT_SHELL_PATH=$(getent passwd "$USER" | cut -d: -f7)
    ZSH_PATH=$(which zsh)
    if [ "$CURRENT_SHELL_PATH" != "$ZSH_PATH" ]; then
        print_info "Attempting to change default shell to Zsh for user $USER..."
        if sudo chsh -s "$ZSH_PATH" "$USER"; then
            print_success "Default shell changed to Zsh for user $USER. Please log out and log back in for the change to take effect."
        else
            print_error "Could not change default shell. Please do it manually using 'sudo chsh -s $ZSH_PATH $USER'."
        fi
    else
        print_info "Default shell is already Zsh ($CURRENT_SHELL_PATH)."
    fi
else
    print_warning "Zsh is not installed. Skipping change default shell."
fi

print_success "Configuration script finished."
print_info "Please review any warnings or errors above."
print_info "Some changes (like default shell, .Xresources, pipx PATH, or newly installed GNOME extensions) may require a logout/login or system reboot to take full effect."
