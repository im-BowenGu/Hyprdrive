#!/bin/bash

echo "🚀 Starting Hyprdrive OS setup..."

# --- Function to detect microarchitecture support ---
detect_microarch() {
    local arch=""
    # Check for x86_64-v4
    if grep -q " x86-64-v4" /proc/cpuinfo; then
        arch="v4"
    # Check for x86_64-v3
    elif grep -q " x86-64-v3" /proc/cpuinfo; then
        arch="v3"
    fi
    echo "$arch"
}

# --- Configure CachyOS Repositories ---
echo "⚙️ Configuring CachyOS repositories based on microarchitecture..."
MICROARCH=$(detect_microarch)
PACMAN_CONF="/etc/pacman.conf"
TEMP_PACMAN_CONF="/tmp/pacman.conf.tmp"

# Backup original pacman.conf
sudo cp "$PACMAN_CONF" "$PACMAN_CONF.bak"

# Filter out existing CachyOS repository entries (v3, v4, and generic)
# and ensure core, extra, multilib are enabled
sed '/^\[cachyos\|^\[core\]\|^\[extra\]\|^\[multilib\]/d' "$PACMAN_CONF.bak" > "$TEMP_PACMAN_CONF"

# Add microarchitecture-specific CachyOS repositories
if [ -n "$MICROARCH" ]; then
    echo "Detected x86_64-${MICROARCH} support. Adding CachyOS ${MICROARCH} repositories."
    cat <<EOF >> "$TEMP_PACMAN_CONF"

[cachyos-${MICROARCH}]
Include = /etc/pacman.d/cachyos-${MICROARCH}-mirrorlist

[cachyos-core-${MICROARCH}]
Include = /etc/pacman.d/cachyos-${MICROARCH}-mirrorlist

[cachyos-extra-${MICROARCH}]
Include = /etc/pacman.d/cachyos-${MICROARCH}-mirrorlist
EOF
else
    echo "No x86_64-v3 or v4 microarchitecture detected. Adding generic CachyOS repositories."
    cat <<EOF >> "$TEMP_PACMAN_CONF"

[cachyos]
Include = /etc/pacman.d/cachyos-mirrorlist
EOF
fi

# Re-add standard Arch repositories
cat <<EOF >> "$TEMP_PACMAN_CONF"

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

#[multilib-testing]
#Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

sudo mv "$TEMP_PACMAN_CONF" "$PACMAN_CONF"
echo "✅ CachyOS repositories configured. Updating pacman databases..."
sudo pacman -Syy # Refresh databases after repo changes

# --- 1. Install Native Arch Packages (including base-devel and CachyOS kernel) ---
echo "📦 Installing native Arch packages, base-devel, and CachyOS kernel..."

# Ensure base-devel is installed first for makepkg
sudo pacman -Syu --needed base-devel git

# Add CachyOS kernel to pkg_list.txt if not already there, or directly install
KERNEL_PKG="linux-cachyos" # Assuming this is the correct package name for CachyOS kernel

if ! grep -q "^$KERNEL_PKG$" pkg_list.txt 2>/dev/null; then
    echo "$KERNEL_PKG" >> pkg_list.txt
fi

if [ -s pkg_list.txt ]; then
    sudo pacman -Syu --needed - < pkg_list.txt
    if [ $? -ne 0 ]; then
        echo "⚠️  Failed to install some native Arch packages. Please check pkg_list.txt and your pacman configuration."
    else
        echo "✅ Native Arch packages and CachyOS kernel installed."
    fi
else
    echo "ℹ️  pkg_list.txt is empty or missing. Skipping native Arch package installation."
fi

# --- 2. Install RUA (AUR Helper) ---
echo "🛠️ Installing RUA (AUR helper)..."
if ! command -v rua &> /dev/null; then
    git clone https://aur.archlinux.org/rua.git /tmp/rua
    if [ $? -eq 0 ]; then
        (cd /tmp/rua && makepkg -si --noconfirm)
        if [ $? -ne 0 ]; then
            echo "⚠️  Failed to install RUA. Please check the logs."
        else
            echo "✅ RUA installed."
        fi
        sudo rm -rf /tmp/rua
    else
        echo "⚠️  Failed to clone RUA repository."
    fi
else
    echo "✅ RUA is already installed."
fi


# --- 3. Install AUR Packages using RUA ---
if [ -s aur_list.txt ]; then
    echo "AUR helper (rua) found. Installing AUR packages from aur_list.txt..."
    rua install -Syu --needed - < aur_list.txt
    if [ $? -ne 0 ]; then
        echo "⚠️  Failed to install some AUR packages. Please check aur_list.txt."
    else
        echo "✅ AUR packages installed."
    fi
else
    echo "ℹ️  aur_list.txt is empty or missing. Skipping AUR package installation."
fi

# --- 4. Install Flatpak Applications ---
if [ -s flatpak_list.txt ]; then
    echo "🚀 Installing Flatpak applications from flatpak_list.txt..."
    while IFS= read -r app_id || [[ -n "$app_id" ]]; do
        if [[ -n "$app_id" && ! "$app_id" =~ ^# ]]; then
            echo "Installing Flatpak: $app_id"
            flatpak install -y flathub "$app_id"
            if [ $? -ne 0 ]; then
                echo "⚠️  Failed to install Flatpak: $app_id"
            fi
        fi
    done < flatpak_list.txt
    echo "✅ Flatpak applications installation attempt completed."
else
    echo "ℹ️  flatpak_list.txt is empty or missing. Skipping Flatpak application installation."
fi

# --- 5. Deploy Dotfiles ---
echo "⚙️ Deploying dotfiles from the 'config/' directory..."
CONFIG_DIR="./config"

if [ -d "$CONFIG_DIR" ]; then
    for item in "$CONFIG_DIR"/*; do
        target_name=$(basename "$item")
        if [ -d "$item" ]; then
            echo "Copying directory $target_name to ~/.config/"
            cp -r "$item" "$HOME/.config/"
        elif [ -f "$item" ]; then
            echo "Copying file $target_name to ~/.config/"
            cp "$item" "$HOME/.config/"
        fi
    done
    echo "✅ Dotfiles deployment completed."
else
    echo "⚠️  'config/' directory not found. Skipping dotfiles deployment."
fi

echo "------------------------------------------"
echo "Hyprdrive OS setup script finished."
echo "Please reboot or log out and back in for some changes to take effect."
echo "NOTE: 'Bloat' removal was not performed as definition was not provided. Please edit pkg_list.txt to remove unwanted packages."