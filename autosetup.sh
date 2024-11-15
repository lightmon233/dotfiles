#!/bin/bash
#the main packages
install_stage=(
    qt5
    fcitx5
    fcitx5-im
    fcitx5-chinese-addons
    openssh
    cava
    neofetch
    neovim
    ranger
    rofi
    alsa-utils
    xclip
    kitty
    go-musicfox
    wqy-zenhei
    adobe-source-han-serif-cn-fonts
    adobe-source-han-sans-cn-fonts
    noto-fonts-cjk
    powerline-fonts
    ttf-font-awesome
    wqy-bitmapfont
    wqy-microhei
    wqy-microhei-lite
    wqy-zenhei
    adobe-source-code-pro-fonts
    ttf-ms-fonts
    noto-fonts-emoji
    google-chrome
    baidunetdisk-bin
    gparted
    ksnip
    shotgun
    zsh
    waybar
    swww 
    swaylock
    wofi 
    wlogout 
    xdg-desktop-portal-hyprland 
    swappy 
    grim 
    slurp 
    thunar 
    btop
    firefox
    thunderbird
    mpv
    pamixer 
    pavucontrol 
    brightnessctl 
    bluez 
    bluez-utils 
    blueman 
    network-manager-applet 
    gvfs 
    thunar-archive-plugin 
    file-roller
    starship 
    papirus-icon-theme 
    ttf-jetbrains-mono-nerd 
    noto-fonts-emoji 
    lxappearance 
    xfce4-settings
    nwg-look
    sddm
    wayland-screenshot
    grimshot
    swaybg
    pyprland
    obs-studio
    cliphist
    wl-clipboard
    polkit-gnome # 图形化密码管理
    udiskie
    ueberzug # ranger需要它来预览图片
    shellcheck # neovim 需要它来检查shell脚本
    w3m 
    imagemagick
    i3-gaps
    i3lock 
    polybar
    optimus-manager
    flameshot
    mpd
    linux-zen-headers # required when u use dkms to install nvidia modules
    pipewire-alsa
    wget
    curl
    pokemon-colorscripts-git
)

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"
INSTLOG="install.log"

# function that would show a progress bar to the user
show_progress() {
    while ps | grep $1 &> /dev/null;
    do
        echo -n "."
        sleep 2
    done
    echo -en "Done!\n"
    sleep 2
}

# function that will test for a package and if not found it will attempt to install it
install_software() {
    # First lets see if the package is there
    if yay -Q $1 &>> /dev/null ; then
        echo -e "$COK - $1 is already installed."
    else
        # no package found so installing
        echo -en "$CNT - Now installing $1 ."
        yay -S --noconfirm $1 &>> $INSTLOG &
        show_progress $!
        # test to make sure package installed
        if yay -Q $1 &>> /dev/null ; then
            echo -e "\e[1A\e[K$COK - $1 was installed."
        else
            # if this is hit then a package is missing, exit to review log
            echo -e "\e[1A\e[K$CER - $1 install had failed, please check the install.log"
            exit
        fi
    fi
}

# clear the screen
clear

# let the user know that we will use sudo
echo -e "$CNT - This script will run some commands that require sudo. You will be prompted to enter your password.
If you are worried about entering your password then you may want to review the content of the script."
sleep 1

# give the user an option to exit out
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to continue with the install (y,n) ' CONTINST
if [[ $CONTINST == "Y" || $CONTINST == "y" ]]; then
    echo -e "$CNT - Setup starting..."
    sudo touch /tmp/hyprv.tmp
else
    echo -e "$CNT - This script will now exit, no changes were made to your system."
    exit
fi

### Modify pacman.conf to use yay ###
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to modify pacman.conf to use yay? (y,n) ' INST
if [[ $INST == "Y" || $INST == "y" ]]; then

    echo "更新 pacman.conf，添加 USTC 源和 archlinuxcn 源..."

    # 备份 pacman.conf
	sudo cp /etc/pacman.conf /etc/pacman.conf.bak

    # 添加 archlinuxcn 源
	if ! grep -q "\[archlinuxcn\]" /etc/pacman.conf; then
	    echo "
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch
" | sudo tee -a /etc/pacman.conf > /dev/null
	else
	  echo "archlinuxcn 源已存在，跳过添加。"
	fi

	# 同步 pacman 数据库
	echo "同步 pacman 数据库..."
	sudo pacman -Sy

	echo "本地信任farseerfc的gpg key..."
	sudo pacman-key --lsign-key "farseerfc@archlinux.org"

	# 安装 archlinuxcn-keyring
	echo "安装 archlinuxcn-keyring..."
	if sudo pacman -S --noconfirm archlinuxcn-keyring; then
	  echo "archlinuxcn-keyring 安装成功。"
	else
	  echo "archlinuxcn-keyring 安装失败，请检查源配置是否正确。"
	  exit 1
	fi

	# 安装 yay
	echo "安装 yay..."
	if sudo pacman -S --noconfirm yay; then
	  echo "yay 安装成功。"
	else
	  echo "yay 安装失败，请检查问题。"
	  exit 1
	fi

fi


### Install all of the above pacakges ####
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install the packages? (y,n) ' INST
if [[ $INST == "Y" || $INST == "y" ]]; then

    # Stage 1 - main components
    echo -e "$CNT - Installing main components, this may take a while..."
    for SOFTWR in ${install_stage[@]}; do
        install_software $SOFTWR 
    done

    # Start the bluetooth service
    echo -e "$CNT - Starting the Bluetooth Service..."
    sudo systemctl enable --now bluetooth.service &>> $INSTLOG
    sleep 2

    # Enable the sddm login manager service
    echo -e "$CNT - Enabling the SDDM Service..."
    sudo systemctl enable sddm &>> $INSTLOG
    sleep 2

    sudo systemctl enable sshd.service
    
fi

### Copy Config Files ###
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to copy config files? (y,n) ' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
    echo -e "$CNT - Copying config files..."
    
    # downloading neovim config
    echo "下载neovim配置"
    git clone https://github.com/lightmon233/nvim ~/.config/
    
    # coping wallpapers
    echo "拷贝壁纸..."
    cp -r ./backgrounds ~/
    
    # installing sddm theme(sddm-sugar-candy)
    echo "安装sddm-sugar-candy主题..."
    git clone https://github.com/Kangie/sddm-sugar-candy ~/sddm-sugar-candy
    sudo cp -r ~/sddm-sugar-candy /usr/share/sddm/themes/
    sudo touch /etc/sddm.conf
    # 运行不了的原因是sudo只给echo提权了，没有给>>提权
    # sudo echo "[Theme]" >> /etc/sddm.conf
    # sudo echo "Current=sddm-sugar-candy" >> /etc/sddm.conf
    echo "[Theme]" | sudo tee -a /etc/sddm.conf.d/sddm.conf
    echo "Current=sddm-sugar-candy" | sudo tee -a /etc/sddm.conf.d/sddm.conf
    sudo cp ~/backgrounds/wallhaven-vmyzkl.jpg /usr/share/sddm/themes/sddm-sugar-candy/Backgrounds
    sudo sed -i '3s/Mountain.jpg/wallhaven-vmyzkl.jpg/' /usr/share/sddm/themes/sddm-sugar-candy/theme.conf
    sudo systemctl enable sddm.service

    
    # .config files
    echo "拷贝.config配置文件"
    cp -r ./config/* ~/.config
    echo "拷贝vim，tmux等配置文件"
    cp -r ./.*  ~/
    
    echo "配置oh-my-zsh及其插件"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    cp ./.zshrc ~/.zshrc
    cp ~/.zshrc ~/.zshrc.bak 
    sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
    sed -i 's/^plugins=(.*)/plugins=()'
    
    fcitx5 config
    echo "配置fcitx5"
	echo "
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
INPUT_METHOD=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=ibus
" | sudo tee -a /etc/environment > /dev/null
  
    git clone https://gitlab.com/imnotpua/grub_gtg.git ~/grub_gtg
    sudo ~/grub_gtg/install.sh

    echo -e "$CNT - Copying successful!"

fi

