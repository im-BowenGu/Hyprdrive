# Hyprdrive OS Configuration

This repository contains the configuration files and scripts to create an opinionated Arch Linux distribution, "Hyprdrive OS", based on the user's current system setup.

## System Personality & Purpose

"Hyprdrive OS" is designed as a high-performance, aesthetically pleasing, and highly customized Arch Linux environment. It caters to users who demand bleeding-edge performance, a sleek visual experience, and a robust platform for development and daily use.

**Core Philosophy:** Performance, Customization, and a Modern Workflow.

**Key Characteristics:**

*   **Foundation**: Arch Linux x86_64, leveraging the performance-tuned **CachyOS Kernel** (currently 6.18.8-3-cachyos) for optimal hardware utilization.
*   **Hardware Focus**: Optimized for modern Intel CPUs (e.g., Intel Ultra 9 275HX) and high-end NVIDIA/Intel integrated graphics, making it suitable for demanding tasks.
*   **Window Manager**: **Hyprland**, a dynamic tiling Wayland compositor, providing a smooth, GPU-accelerated desktop experience with extensive customization.
*   **Aesthetics**:
    *   **Color Scheme**: A sophisticated dark theme with a prominent orange primary color, adhering to Material Design color roles for a consistent and modern look.
    *   **Window Decorations**: Features rounded corners for a soft, contemporary feel, subtle blur effects for transparent elements, and unique purplish shadows that add depth and character.
    *   **Icons**: **Colloid Icon Theme**, enhancing the visual consistency.
*   **Terminal**: **Kitty**, a fast, GPU-based terminal emulator, crucial for developers and power users.
*   **Status Bar**: **Waybar**, a highly customizable Wayland bar, offering rich system information and quick access to controls.
*   **Package Management**: A hybrid approach leveraging `pacman` for native Arch packages, `rua` for AUR packages, and `flatpak` for sandboxed applications, providing flexibility and access to a vast software ecosystem.
*   **Origin**: Based on the well-regarded "MyLinuxForWork" (ML4W) dotfiles, ensuring a thoughtfully designed and coherent system from the ground up.

## Project Structure

*   `extract-dots.sh`: A script to extract essential configuration files (dotfiles) and package lists from the current system.
*   `config/`: This directory holds the extracted dotfiles, organized by application.
*   `pkg_list.txt`: A list of native Arch Linux packages installed on the original system.
*   `aur_list.txt`: A list of AUR (Arch User Repository) packages installed on the original system.
*   `flatpak_list.txt`: A list of Flatpak applications installed on the original system.
*   `setup_hyprdrive.sh`: A comprehensive setup script designed to be run on a newly installed Arch Linux system. This script automates:
    *   Dynamic configuration of CachyOS repositories based on CPU microarchitecture (x86_64-v3/v4).
    *   Installation of `base-devel` and `git`.
    *   Building and installation of `rua` (AUR helper) from source.
    *   Installation of native Arch Linux packages (including the CachyOS kernel) from `pkg_list.txt`.
    *   Installation of AUR packages from `aur_list.txt` using `rua`.
    *   Installation of Flatpak applications from `flatpak_list.txt`.
    *   Deployment of dotfiles from the `config/` directory to the user's home.

## How to Build Your Custom ISO

This repository is set up to allow you to build a custom Arch Linux ISO that includes these configurations and scripts.

**Prerequisites:**

1.  **Arch Linux Installation:** You need an existing Arch Linux installation (or a similar environment) to build the ISO.
2.  **`archiso` installed:** Ensure `archiso` is installed (`sudo pacman -S archiso`) and your `pacman` keyring and databases are fully functional.

**Steps:**

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/im-BowenGu/Hyprdrive.git
    cd Hyprdrive
    ```
2.  **Prepare the `archiso` profile:**
    ```bash
    mkdir -p ~/hyprdrive-iso
    cp -r /usr/share/archiso/configs/releng/ ~/hyprdrive-iso/hyprdrive-profile
    ```
3.  **Copy custom files to the profile:**
    ```bash
    mkdir -p ~/hyprdrive-iso/hyprdrive-profile/airootfs/etc/skel/.config
    mkdir -p ~/hyprdrive-iso/hyprdrive-profile/airootfs/root

    cp -r config/ ~/hyprdrive-iso/hyprdrive-profile/airootfs/etc/skel/
    cp setup_hyprdrive.sh pkg_list.txt aur_list.txt flatpak_list.txt README.md extract-dots.sh ~/hyprdrive-iso/hyprdrive-profile/airootfs/root/
    ```
4.  **Modify `archiso` profile's `packages.x86_64`:**
    Ensure essential packages and the CachyOS kernel are included. This involves editing the `~/hyprdrive-iso/hyprdrive-profile/packages.x86_64` file.

    Example content to ensure is present (remove `archinstall` if present):
    ```
    base-devel
    git
    pacman-contrib
    dialog
    networkmanager
    os-prober
    linux-cachyos
    # ... other base packages ...
    ```
    You can use the following command to update it:
    ```bash
    PKG_LIST_PATH="/home/secret-star/hyprdrive-iso/hyprdrive-profile/packages.x86_64"
    PACKAGES_TO_ADD=(
        base-devel
        git
        pacman-contrib
        dialog
        networkmanager
        os-prober
        linux-cachyos
    )
    (
        grep -v '^archinstall$' "$PKG_LIST_PATH"
        for pkg in "${PACKAGES_TO_ADD[@]}"; do echo "$pkg"; done
    ) | sort -u > /tmp/new_packages.x86_64
    sudo mv /tmp/new_packages.x86_64 "$PKG_LIST_PATH"
    ```

5.  **Modify `archiso` profile's `pacman.conf` and `profiledef.sh`:**
    Add CachyOS repositories to `~/hyprdrive-iso/hyprdrive-profile/pacman.conf` for the build process and ensure `setup_hyprdrive.sh` is executable.

    ```bash
    PACMAN_CONF_PATH="/home/secret-star/hyprdrive-iso/hyprdrive-profile/pacman.conf"
    PROFILEDEF_PATH="/home/secret-star/hyprdrive-iso/hyprdrive-profile/profiledef.sh"

    sudo bash -c "cat <<EOF >> \"$PACMAN_CONF_PATH\"

# CachyOS Repositories for archiso build environment
# These are enabled to allow installation of CachyOS packages during ISO creation.
# The installed system will dynamically enable microarchitecture-specific repos via setup_hyprdrive.sh.

[cachyos-v4]
Server = https://cachyos.org/repo/x86_64-v4/\$repo/\$arch

[cachyos-core-v4]
Server = https://cachyos.org/repo/x86_64-v4/\$repo/\$arch

[cachyos-extra-v4]
Server = https://cachyos.org/repo/x86_64-v4/\$repo/\$arch

[cachyos-v3]
Server = https://cachyos.org/repo/x86_64-v3/\$repo/\$arch

[cachyos-core-v3]
Server = https://cachyos.org/repo/x86_64-v3/\$repo/\$arch

[cachyos-extra-v3]
Server = https://cachyos.org/repo/x86_64-v3/\$repo/\$arch

[cachyos]
Server = https://cachyos.org/repo/x86_64/\$repo/\$arch
EOF"

    sudo sed -i '/^file_permissions=(/a \ \ \ \ \ \ \ \ ["/root/setup_hyprdrive.sh"]="0:0:755"' "$PROFILEDEF_PATH"
    ```

6.  **Build the ISO:**
    ```bash
    sudo mkarchiso -v -o ~/hyprdrive-iso/output/ ~/hyprdrive-iso/hyprdrive-profile
    ```

## How to Use the Custom ISO

1.  **Boot from the ISO:** Boot your target machine using the custom ISO you just built.
2.  **Install Arch Linux:** Follow the standard Arch Linux installation guide.
3.  **Run `setup_hyprdrive.sh`:** After the base system installation (and potentially user creation), log in and navigate to `/root/`.
    ```bash
    cd /root/
    sudo ./setup_hyprdrive.sh
    ```
    This script will install all your configured packages and deploy your dotfiles.
