#!/bin/bash

# ==============================================================================
# 1. 全局配置与软件包列表
# ==============================================================================
INSTALL_STAGE=(
    qt5 fcitx5 fcitx5-im fcitx5-chinese-addons openssh cava neofetch neovim ranger 
    rofi alsa-utils xclip kitty go-musicfox wqy-zenhei adobe-source-han-serif-cn-fonts 
    adobe-source-han-sans-cn-fonts noto-fonts-cjk powerline-fonts ttf-font-awesome 
    wqy-bitmapfont wqy-microhei wqy-microhei-lite adobe-source-code-pro-fonts 
    ttf-ms-fonts noto-fonts-emoji google-chrome baidunetdisk-bin gparted ksnip 
    shotgun zsh waybar swww swaylock wofi wlogout xdg-desktop-portal-hyprland 
    swappy grim slurp thunar btop firefox thunderbird mpv pamixer pavucontrol 
    brightnessctl bluez bluez-utils blueman network-manager-applet gvfs 
    thunar-archive-plugin file-roller starship papirus-icon-theme lxappearance 
    ttf-jetbrains-mono-nerd xfce4-settings nwg-look sddm wayland-screenshot 
    grimshot swaybg pyprland obs-studio cliphist wl-clipboard polkit-gnome 
    udiskie ueberzug shellcheck w3m imagemagick i3-gaps i3lock polybar 
    optimus-manager flameshot mpd linux-zen-headers pipewire-alsa wget curl 
    pokemon-colorscripts-git
)

# 终端颜色提示
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"
INSTLOG="install.log"

# ==============================================================================
# 2. 核心辅助工具函数（已加入自动跳过机制）
# ==============================================================================

# 进度条显示（通过检测 PID 是否存活）
show_progress() {
    local pid=$1
    while kill -0 "$pid" 2>/dev/null; do
        echo -n "."
        sleep 2
    done
    echo -en "Done!\n"
    sleep 1
}

# 软件安装核心逻辑（加入不可用软件自动跳过）
install_software() {
    local pkg=$1
    
    # 1. 检查本地是否已经安装
    if yay -Q "$pkg" &>> /dev/null ; then
        echo -e "$COK - $pkg 已经安装."
        return 0
    fi

    # 2. 检查远程软件源（包括 AUR）中是否存在这个包
    # yay -Si 可以同时检查官方源和 AUR，如果返回非 0 说明源里没有这个包
    if ! yay -Si "$pkg" &>> /dev/null ; then
        echo -e "$CWR - 软件源中未找到包 '$pkg' (可能已被下架或更名)，已自动跳过。"
        return 0
    fi

    # 3. 确认源里有包，开始安装
    echo -en "$CNT - 正在安装 $pkg "
    yay -S --noconfirm "$pkg" &>> "$INSTLOG" &
    show_progress $!
    
    # 4. 再次验证是否安装成功
    if yay -Q "$pkg" &>> /dev/null ; then
        echo -e "\e[1A\e[K$COK - $pkg 安装成功."
    else
        # 如果源里有但安装失败了（比如编译报错、网络中断），我们依然选择提示而不退出
        echo -e "\e[1A\e[K$CER - $pkg 安装过程中出错，已跳过。请检查 $INSTLOG"
    fi
}
# 提示确认函数
confirm_action() {
    local message=$1
    local choice
    read -rep "$CAC - $message (y/n) " choice
    if [[ "$choice" == "Y" || "$choice" == "y" ]]; then
        return 0 # 代表 True
    else
        return 1 # 代表 False
    fi
}

# ==============================================================================
# 3. 独立阶段模块
# ==============================================================================

# 阶段一：配置软件源与环境准备
setup_pacman_and_yay() {
    if ! confirm_action "是否修改 pacman.conf 并自动安装配置 yay 软件源？"; then
        return 0
    fi

    echo -e "$CNT - 更新 pacman.conf，添加 USTC 源和 archlinuxcn 源..."
    sudo cp /etc/pacman.conf /etc/pacman.conf.bak

    if ! grep -q "\[archlinuxcn\]" /etc/pacman.conf; then
        echo "
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch
" | sudo tee -a /etc/pacman.conf > /dev/null
    else
        echo -e "$CNT - archlinuxcn 源已存在，跳过添加。"
    fi

    echo -e "$CNT - 同步 pacman 数据库并导入 GPG 密钥..."
    sudo pacman -Sy
    sudo pacman-key --lsign-key "farseerfc@archlinux.org"

    echo -e "$CNT - 安装 archlinuxcn-keyring..."
    if ! sudo pacman -S --noconfirm archlinuxcn-keyring; then
        echo -e "$CER - archlinuxcn-keyring 安装失败，请检查网络或配置。"
        exit 1
    fi

    echo -e "$CNT - 安装 yay..."
    if ! sudo pacman -S --noconfirm yay; then
        echo -e "$CER - yay 安装失败。"
        exit 1
    fi
}

# 阶段二：批量拉取并安装软件包
install_all_packages() {
    if ! confirm_action "是否现在开始安装预设的软件包？"; then
        return 0
    fi

    echo -e "$CNT - 开始安装核心系统组件，这可能需要较长时间..."
    for SOFTWR in "${INSTALL_STAGE[@]}"; do
        install_software "$SOFTWR"
    done

    echo -e "$CNT - 正在启动相关系统服务..."
    sudo systemctl enable --now bluetooth.service &>> "$INSTLOG"
    sudo systemctl enable --now sddm.service &>> "$INSTLOG"
    sudo systemctl enable --now sshd.service &>> "$INSTLOG"
}

# 阶段三：配置文件与主题的部署
copy_config_files() {
    if ! confirm_action "是否复制并部署本地/远程配置文件？"; then
        return 0
    fi

    echo -e "$CNT - 正在部署配置文件..."
    mkdir -p ~/.config

    # 1. Neovim 部署
    echo "-> 下载 Neovim 配置..."
    rm -rf ~/.config/nvim
    git clone https://github.com/lightmon233/nvim ~/.config/nvim
    
    # 2. 壁纸部署
    echo "-> 拷贝壁纸..."
    if [ -d "./backgrounds" ]; then
        cp -r ./backgrounds ~/
    fi
    
    # 3. SDDM 主题配置
    echo "-> 安装 sddm-sugar-candy 主题..."
    rm -rf ~/sddm-sugar-candy
    git clone https://github.com/Kangie/sddm-sugar-candy ~/sddm-sugar-candy
    sudo cp -r ~/sddm-sugar-candy /usr/share/sddm/themes/
    sudo mkdir -p /etc/sddm.conf.d
    
    echo -e "[Theme]\nCurrent=sddm-sugar-candy" | sudo tee /etc/sddm.conf.d/sddm.conf > /dev/null
    
    if [ -f "~/backgrounds/wallhaven-vmyzkl.jpg" ]; then
        sudo cp ~/backgrounds/wallhaven-vmyzkl.jpg /usr/share/sddm/themes/sddm-sugar-candy/Backgrounds/
        sudo sed -i 's/Background=.*/Background="wallhaven-vmyzkl.jpg"/' /usr/share/sddm/themes/sddm-sugar-candy/theme.conf
    fi

    # 4. 拷贝本地基础 Dotfiles（修复了原先 .* 误拷贝上级目录的 Bug）
    echo "-> 拷贝基础本地配置文件..."
    [ -d "./config" ] && cp -r ./config/* ~/.config/
    # 安全地拷贝当前目录下除 . 和 .. 之外的所有隐藏文件
    find . -maxdepth 1 -name ".*" ! -name "." ! -name ".." -exec cp -r {} ~/ \;
    
    # 5. Zsh & Oh My Zsh 自动化（修复了会阻塞终端的 Bug）
    echo "-> 配置 oh-my-zsh 及其插件..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    local zsh_custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    rm -rf "$zsh_custom_dir/themes/powerlevel10k" "$zsh_custom_dir/plugins/zsh-autosuggestions" "$zsh_custom_dir/plugins/zsh-syntax-highlighting"
    
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom_dir/themes/powerlevel10k"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom_dir/plugins/zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom_dir/plugins/zsh-syntax-highlighting"
    
    # 覆盖与修正 .zshrc
    [ -f "./.zshrc" ] && cp ./.zshrc ~/.zshrc
    sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
    sed -i 's/^plugins=(.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
    
    # 6. Fcitx5 环境变量配置
    echo "-> 配置 fcitx5 输入法环境变量..."
    echo "GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
INPUT_METHOD=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=ibus" | sudo tee -a /etc/environment > /dev/null
  
    # 7. Grub 主题
    echo "-> 安装 GRUB 美化主题..."
    rm -rf ~/grub_gtg
    git clone https://gitlab.com/imnotpua/grub_gtg.git ~/grub_gtg
    chmod +x ~/grub_gtg/install.sh
    sudo ~/grub_gtg/install.sh

    echo -e "$COK - 阶段三：所有配置复制完成！"
}

# ==============================================================================
# 4. 脚本主入口执行流
# ==============================================================================
main() {
    clear
    echo -e "$CNT - 欢迎使用 Arch Linux 自动化装机部署脚本"
    echo -e "$CNT - 本脚本部分操作需要用到 sudo 权限。如果你不放心，请随时查阅脚本源码。"
    sleep 1

    if ! confirm_action "您是否确认要开始执行此安装脚本？"; then
        echo -e "$CNT - 脚本已退出，未对您的系统做出任何更改。"
        exit 0
    fi
    
    sudo touch /tmp/hyprv.tmp

    # 按阶段解耦调用
    setup_pacman_and_yay
    install_all_packages
    copy_config_files

    echo -e "\n$COK - 全部装机与配置流程已经全部搞定！建议重启系统体验新环境。 🎉"
}

# 启动脚本
main
