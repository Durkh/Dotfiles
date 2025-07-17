#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define the list of packages to install
PACKAGES_COMMON="git zsh"
PACKAGES_APT="podman-toolbox flatpak" 
PACKAGES_DNF="toolbox flatpak" 
PACKAGES_YAY="toolbox wezterm" 

# --- Helper Functions ---
print_info() {
    echo -e "\033[34mINFO: $1\033[0m"
}

print_success() {
    echo -e "\033[32mSUCCESS: $1\033[0m"
}

print_error() {
    echo -e "\033[31mERROR: $1\033[0m" >&2
}

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_info "Oh My Zsh is already installed."
    else
        print_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh installed."
    fi
}

# --- Distribution specific installation ---

# Check for /etc/os-release to determine the distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
    OS_LIKE=$(echo "$ID_LIKE" | tr '[:upper:]' '[:lower:]')
else
    print_error "Cannot determine Linux distribution. /etc/os-release not found."
    exit 1
fi

print_info "Detected distribution: $OS"

if [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS_LIKE" == *"debian"* ]]; then
    print_info "Using apt package manager."
    sudo apt update
    sudo apt install -y $PACKAGES_COMMON $PACKAGES_APT

    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    # Wezterm installation
    if ! command -v wezterm &> /dev/null; then
        print_info "Attempting to install WezTerm for Debian/Ubuntu..."
        flatpak install flathub org.wezfurlong.wezterm
    else
        print_info "Wezterm already installed."
    fi

    print_success "APT packages installed."

elif [[ "$OS" == "fedora" ]]; then
    print_info "Using dnf package manager."
    sudo dnf install -y $PACKAGES_COMMON $PACKAGES_DNF

    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    # Wezterm installation
    if ! command -v wezterm &> /dev/null; then
        print_info "Attempting to install WezTerm for Fedora..."
        flatpak install flathub org.wezfurlong.wezterm
    else
        print_info "Wezterm already installed."
    fi
    print_success "DNF packages installed."

elif [[ "$OS" == "arch" || "$OS_LIKE" == *"arch"* ]]; then
    print_info "Using pacman/yay package manager."
    # Install base-devel if not present, for makepkg
    sudo pacman -Syu --needed --noconfirm git base-devel $PACKAGES_COMMON

    # Check for yay
    if ! command -v yay &> /dev/null; then
        print_info "yay not found. Installing yay..."
        TEMP_DIR=$(mktemp -d)
        current_dir=$(pwd)
        cd "$TEMP_DIR"
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd "$current_dir" # Go back to the original directory
        rm -rf "$TEMP_DIR"
        print_success "yay installed successfully."
    else
        print_info "yay is already installed."
    fi

    # Install packages with yay (includes AUR packages like wezterm if not in official repos)
    # For packages already installed by pacman, yay will skip them.
    if [ -n "$PACKAGES_YAY" ]; then
        print_info "Installing AUR packages with yay: $PACKAGES_YAY"
        yay -Syu --needed --noconfirm $PACKAGES_YAY
    fi
    print_success "Pacman/yay packages installed."

else
    print_error "Unsupported Linux distribution: $OS"
    print_error "Please install the following packages manually: $PACKAGES_COMMON $PACKAGES_YAY"
    exit 1
fi

# Install Oh My Zsh
install_oh_my_zsh

print_success "All packages installed successfully!"
echo "Consider logging out and back in or rebooting for all changes to take effect, especially for zsh as the default shell."
