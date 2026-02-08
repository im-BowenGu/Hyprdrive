#!/bin/bash

# Define the backup directory
BACKUP_DIR="$HOME/Hyprdrive-Config"
mkdir -p "$BACKUP_DIR/config"

echo " Starting Hyprdrive OS configuration extraction..."

# 1. Copy common Hyprland & Wayland configs
configs=( "hypr" "kitty" "waybar" "wofi" "mako" "swaylock" "neofetch" "fastfetch" )

for folder in "${configs[@]}"; do
    if [ -d "$HOME/.config/$folder" ]; then
        cp -r "$HOME/.config/$folder" "$BACKUP_DIR/config/"
        echo " Backed up $folder"
    fi
done

# 2. Extract Package Lists (The "DNA" of your distro)
echo "📄 Generating package lists..."
pacman -Qqen > "$BACKUP_DIR/pkg_list.txt"     # Native Arch pkgs
pacman -Qqem > "$BACKUP_DIR/aur_list.txt"     # AUR pkgs (CachyOS/Yay)
flatpak list --columns=application > "$BACKUP_DIR/flatpak_list.txt"

# 3. Create a basic README
echo "# Hyprdrive OS Config" > "$BACKUP_DIR/README.md"
echo "Extracted on: $(date)" >> "$BACKUP_DIR/README.md"
echo "CPU: Intel Ultra 9 | Kernel: CachyOS" >> "$BACKUP_DIR/README.md"

echo "------------------------------------------"
echo "Done! Your files are at: $BACKUP_DIR"
