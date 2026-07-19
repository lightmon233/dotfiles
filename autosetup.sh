#!/bin/bash

# ==============================================================================
# 1. Global Configuration and Package List
# ==============================================================================
INSTALL_STAGE=(
    # --- 基础工具与核心依赖 ---
    wget curl unzip xclip wl-clipboard libnotify gvfs shellcheck

    # --- 窗口管理器与核心组件 (Hyprland / i3) ---
    hyprland xdg-desktop-portal-hyprland pyprland
    i3-wm i3blocks i3status polybar picom feh i3lock swaylock

    # --- 桌面环境配套与外挂组件 ---
    waybar rofi wofi wlogout swaybg lxappearance nwg-look sddm xfce4-settings
    polkit-gnome udiskie cliphist network-manager-applet dunst

    # --- 终端、Shell 与开发环境 ---
    kitty zsh starship neovim nodejs tree-sitter-cli npm
    fastfetch btop ranger w3m ueberzug imagemagick cava pokemon-colorscripts-git

    # --- 字体与国际化输入法 (中文/Emoji/Nerd) ---
    qt5 fcitx5 fcitx5-im fcitx5-chinese-addons
    wqy-zenhei wqy-bitmapfont wqy-microhei wqy-microhei-lite
    adobe-source-han-serif-cn-fonts adobe-source-han-sans-cn-fonts adobe-source-code-pro-fonts
    noto-fonts-cjk noto-fonts-emoji powerline-fonts ttf-ms-fonts ttf-jetbrains-mono-nerd

    # --- 音频与蓝牙管理 (PipeWire) ---
    alsa-utils pamixer pavucontrol pipewire-alsa pipewire-pulse mpd
    bluez bluez-utils blueman brightnessctl

    # --- 日常应用与文件管理 ---
    thunar thunar-archive-plugin file-roller gparted
    firefox thunderbird google-chrome mpv

    # --- 截图、录屏与图像处理 ---
    flameshot ksnip shotgun swappy grim slurp obs-studio scrot

    # --- 内核头文件 (驱动/特定模块编译所需) ---
    linux-zen-headers

    # --- 主题外观 ---
    papirus-icon-theme
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
    find . -maxdepth 1 -name ".*" ! -name "." ! -name ".." -exec cp -r {} ~/ \;

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
    cd ~/grub_gtg
    sudo ~/grub_gtg/install.sh

    # 8. Waybar & Polybar Themes
    echo "-> Installing Bar themes..."
    chmod +x ~/.config/waybar/cava-internal.sh
    rm -rf ~/polybar-themes
    git clone --depth=1 https://github.com/adi1090x/polybar-themes.git ~/polybar-themes
    chmod +x ~/polybar-themes/setup.sh
    cd ~/polybar-themes
    ~/polybar-themes/setup.sh <<< "1" 2>&1

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

    # 【修复重点】使用 sudo 自带的 SUDO_USER 变量，如果为空则回退到当前 USER
    local EFFECTIVE_USER="${SUDO_USER:-$USER}"

    echo -e "$CAT - Authenticating sudo privileges..."
    
    # 【优雅合并】一次性通过 sudo 验证并直接写入免密规则，绝不触发第二次弹窗
    if sudo sh -c "echo '$EFFECTIVE_USER ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/99-autosetup-tmp"; then
        echo -e "$COK - Sudo passwordless privilege granted temporarily."
    else
        echo -e "$CER - Sudo authentication failed. Exiting."
        exit 1
    fi
    
    # 安全网：确保退出或中断时清理免密规则
    # 注意：这里需要使用 sudo rm，因为免密规则已经生效，这行命令在退出时不需要输入密码
    trap 'sudo rm -f /etc/sudoers.d/99-autosetup-tmp 2>/dev/null' EXIT

    if ! confirm_action "Are you sure you want to start the installation?"; then
        echo -e "$CNT - Script exited. No changes were made to your system."
        exit 0
    fi
    
    sudo touch /tmp/hyprv.tmp

    # 执行后续流程
    setup_pacman_and_yay
    install_all_packages
    copy_config_files

    echo -e "\n$COK - All installations and configurations are completed! Reboot is highly recommended. 🎉"
}

# Fire up the script
main
