#!/bin/bash

# ==============================================================================
# 1. Global Configuration and Package List
# ==============================================================================
INSTALL_STAGE=(
    qt5 fcitx5 fcitx5-im fcitx5-chinese-addons openssh cava fastfetch neovim ranger 
    rofi alsa-utils xclip kitty wqy-zenhei adobe-source-han-serif-cn-fonts 
    adobe-source-han-sans-cn-fonts noto-fonts-cjk powerline-fonts 
    wqy-bitmapfont wqy-microhei wqy-microhei-lite adobe-source-code-pro-fonts 
    ttf-ms-fonts noto-fonts-emoji google-chrome gparted ksnip 
    shotgun zsh waybar swaylock wofi wlogout xdg-desktop-portal-hyprland 
    swappy grim slurp thunar btop firefox thunderbird mpv pamixer pavucontrol 
    brightnessctl bluez bluez-utils blueman network-manager-applet gvfs 
    thunar-archive-plugin file-roller starship papirus-icon-theme lxappearance 
    ttf-jetbrains-mono-nerd xfce4-settings nwg-look sddm
    swaybg pyprland obs-studio cliphist wl-clipboard polkit-gnome 
    udiskie ueberzug shellcheck w3m imagemagick i3lock polybar 
    flameshot mpd linux-zen-headers pipewire-alsa wget curl 
    pokemon-colorscripts-git hyprland
)

# Terminal colored status tags
CNT="[\e[1;36mNOTE\e[0m]"       # 青色 (Cyan) - 提示信息
COK="[\e[1;32mOK\e[0m]"         # 绿色 (Green) - 成功
CER="[\e[1;31mERROR\e[0m]"      # 红色 (Red) - 错误
CAT="[\e[1;33mATTENTION\e[0m]"  # 黄色 (Yellow) - 【已修复】亮黄色，任何背景下都极明显
CWR="[\e[1;35mWARNING\e[0m]"    # 紫色 (Magenta) - 警告
CAC=$'[\e[1;34mACTION\e[0m]'     # 蓝色 (Blue) - 【优化】改为蓝色，与动作交互更配
INSTLOG="install.log"

# Get current real user (not root)
REAL_USER=$(logname || echo "$USER")

# ==============================================================================
# 2. Core Helper Functions
# ==============================================================================

# Progress indicator (checks if PID is still alive)
show_progress() {
    local pid=$1
    while kill -0 "$pid" 2>/dev/null; do
        echo -n "."
        sleep 2
    done
    echo -en "Done!\n"
    sleep 1
}

# Software installation logic
install_software() {
    local pkg=$1
    
    # 1. Check if already installed locally
    if yay -Q "$pkg" &>> /dev/null ; then
        echo -e "$COK - $pkg is already installed."
        return 0
    fi

    # 2. Check if package exists in repositories (including AUR)
    if ! yay -Si "$pkg" &>> /dev/null ; then
        echo -e "$CWR - Package '$pkg' not found in repositories. Skipping."
        return 0
    fi

    # 3. Package exists, install in background with show_progress.
    echo -en "$CNT - Installing $pkg "
    yay -S --noconfirm "$pkg" >> "$INSTLOG" 2>&1 &
    show_progress $!
    
    # 4. Double check if installation succeeded
    if yay -Q "$pkg" &>> /dev/null ; then
        echo -e "\e[1A\e[K$COK - $pkg installed successfully."
    else
        echo -e "\e[1A\e[K$CER - Installation of $pkg failed. Skipping. Check $INSTLOG"
    fi
}

# User confirmation dialog
confirm_action() {
    local message=$1
    local choice
    read -rep "$CAC - $message (y/n) " choice
    if [[ "$choice" == "Y" || "$choice" == "y" ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# 3. Independent Stage Modules
# ==============================================================================

# Stage 1: Pacman and Yay Repository Configuration
setup_pacman_and_yay() {
    if ! confirm_action "Modify pacman.conf and automatically set up yay repositories?"; then
        return 0
    fi

    echo -e "$CNT - Updating pacman.conf, adding USTC and archlinuxcn mirrors..."
    sudo cp /etc/pacman.conf /etc/pacman.conf.bak

    if ! grep -q "\[archlinuxcn\]" /etc/pacman.conf; then
        echo "
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch
" | sudo tee -a /etc/pacman.conf > /dev/null
    else
        echo -e "$CNT - archlinuxcn repository already exists. Skipping."
    fi

    echo -e "$CNT - Syncing pacman databases and importing GPG keys..."
    sudo pacman -Sy
    sudo pacman-key --lsign-key "farseerfc@archlinux.org"

    echo -e "$CNT - Installing archlinuxcn-keyring..."
    if ! sudo pacman -S --noconfirm archlinuxcn-keyring; then
        echo -e "$CER - Failed to install archlinuxcn-keyring. Check your network or config."
        exit 1
    fi

    echo -e "$CNT - Installing yay..."
    if ! sudo pacman -S --noconfirm yay; then
        echo -e "$CER - Failed to install yay."
        exit 1
    fi
}

# Stage 2: Batch Package Installation
install_all_packages() {
    if ! confirm_action "Would you like to start installing the preset packages now?"; then
        return 0
    fi

    echo -e "$CNT - Starting core system components installation..."
    > "$INSTLOG"
    
    for SOFTWR in "${INSTALL_STAGE[@]}"; do
        install_software "$SOFTWR"
    done

    echo -e "$CNT - Enabling system services..."
    sudo systemctl enable --now bluetooth.service &>> "$INSTLOG"
    sudo systemctl enable sddm.service &>> "$INSTLOG"
    sudo systemctl enable --now sshd.service &>> "$INSTLOG"
}

# Stage 3: Dotfiles and Themes Deployment
copy_config_files() {
    if ! confirm_action "Deploy and copy local/remote configuration files?"; then
        return 0
    fi

    echo -e "$CNT - Deploying configuration files..."
    mkdir -p ~/.config

    # 1. Neovim Deployment
    echo "-> Downloading Neovim configuration..."
    rm -rf ~/.config/nvim
    git clone https://github.com/lightmon233/nvim ~/.config/nvim
    
    # 2. Wallpapers Deployment
    echo "-> Copying wallpapers..."
    if [ -d "./Wallpapers" ]; then
        cp -r ./Wallpapers ~/
    fi
    
    # 3. SDDM Theme Setup
    echo "-> Installing sddm-sugar-candy theme..."
    rm -rf ~/sddm-sugar-candy
    git clone https://github.com/Kangie/sddm-sugar-candy ~/sddm-sugar-candy
    sudo cp -r ~/sddm-sugar-candy /usr/share/sddm/themes/
    sudo mkdir -p /etc/sddm.conf.d
    
    echo -e "[Theme]\nCurrent=sddm-sugar-candy" | sudo tee /etc/sddm.conf.d/sddm.conf > /dev/null
    
    if [ -f "$HOME/Wallpapers/wallhaven-vmyzkl.jpg" ]; then
        sudo cp "$HOME/Wallpapers/wallhaven-vmyzkl.jpg" /usr/share/sddm/themes/sddm-sugar-candy/Backgrounds/
        sudo sed -i 's/Background=.*/Background="Backgrounds\/wallhaven-vmyzkl.jpg"/' /usr/share/sddm/themes/sddm-sugar-candy/theme.conf
    fi

    # 4. Copy Local Dotfiles
    echo "-> Copying basic local configuration files..."
    [ -d "./.config" ] && cp -r ./.config/* ~/.config/
    find . -maxdepth 1 -name ".*" ! -name "." ! -name "..-exec cp -r {} ~/ \;"
    
    # 5. Zsh & Oh My Zsh Automation
    echo "-> Configuring oh-my-zsh and plugins..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    local zsh_custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    rm -rf "$zsh_custom_dir/themes/powerlevel10k" "$zsh_custom_dir/plugins/zsh-autosuggestions" "$zsh_custom_dir/plugins/zsh-syntax-highlighting"
    
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom_dir/themes/powerlevel10k"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom_dir/plugins/zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom_dir/plugins/zsh-syntax-highlighting"
    
    # Overwrite and adjust .zshrc
    [ -f "./.zshrc" ] && cp ./.zshrc ~/.zshrc
    # No need to replace these lines, since they are already included in .zshrc
    # sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
    # sed -i 's/^plugins=(.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
    
    # 6. Fcitx5 Environment Setup
    echo "-> Setting up fcitx5 environment variables..."
    echo "GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
INPUT_METHOD=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=ibus" | sudo tee -a /etc/environment > /dev/null
  
    # 7. Grub Theme
    echo "-> Installing GRUB themes..."
    rm -rf ~/grub_gtg
    git clone https://gitlab.com/imnotpua/grub_gtg.git ~/grub_gtg
    chmod +x ~/grub_gtg/install.sh
    sudo ~/grub_gtg/install.sh

    echo -e "$COK - Stage 3: All configuration files successfully deployed!"
}

# ==============================================================================
# 4. Main Script Execution Flow
# ==============================================================================
main() {
    clear
    echo -e "$CNT - Welcome to Arch Linux Automated Deployment Script"
    
    # 拒绝直接使用 sudo 运行本脚本
    if [ "$EUID" -eq 0 ]; then
        echo -e "$CER - Please DO NOT run this script with sudo directly."
        echo -e "$CNT - Run it as normal user: ./autosetup.sh"
        exit 1
    fi

    echo -e "$CNT - This script requires sudo privileges once at startup to unlock full automation."
    sleep 1

    # Handshake with sudo to get temporary passwordless privilege
    echo -e "$CAT - Authenticating sudo privileges..."
    if sudo -v; then
        # Dynamically inject temporary passwordless rule for the current user
        echo "$REAL_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/99-autosetup-tmp > /dev/null
    else
        echo -e "$CER - Sudo authentication failed. Exiting."
        exit 1
    fi
    
    # Safety Net: Ensure the passwordless rule is completely removed upon exit/interruption
    trap 'sudo rm -f /etc/sudoers.d/99-autosetup-tmp 2>/dev/null' EXIT

    if ! confirm_action "Are you sure you want to start the installation?"; then
        echo -e "$CNT - Script exited. No changes were made to your system."
        exit 0
    fi
    
    sudo touch /tmp/hyprv.tmp

    # Executing operational stages flawlessly with zero pass prompts
    setup_pacman_and_yay
    install_all_packages
    copy_config_files

    echo -e "\n$COK - All installations and configurations are completed! Reboot is highly recommended. 🎉"
}

# Fire up the script
main
