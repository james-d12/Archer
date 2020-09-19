#!/usr/bin/env bash

. ./arch-config.sh
. resources/packages

if ! ping -c 1 -q google.com >&/dev/null; then
    echo -e "${MSGCOLOUR}You are not connected to the internet, attempting connection solutions.....${NC}"
    echo -e "${MSGCOLOUR}Attempting connection via nmtui....${NC}"
    nmtui 
    echo -e "${MSGCOLOUR}Attempting connection via wifi-menu....${NC}"
    wifi-menu
fi

echo "-----------------------------------------"
echo "--     Installing Pacman Packages      --"
echo "-----------------------------------------"
echo -e "${MSGCOLOUR}Installing packages.....${NC}"
defile="resources/${desktopenvironment}" && . ./$defile
sudo pacman -S --noconfirm --needed ${depackages[@]}
sudo pacman -S --noconfirm --needed ${packages[@]}

if [ ! ${#packagesaur[@]} -eq 0 ]; then  
    echo "-----------------------------------------"
    echo "--      Installing AUR Packages        --"
    echo "-----------------------------------------"
    if ! command -v yay > /dev/null; then 
        echo -e "${MSGCOLOUR}Installing YAY.....${NC}"
        git clone https://aur.archlinux.org/yay.git
        cd yay 
        makepkg -si
    fi
    echo -e "${MSGCOLOUR}Installing AUR packages.....${NC}"
    yay -S --batchinstall --cleanafter --noconfirm --needed ${packagesaur[@]}
fi

if command -v pip > /dev/null; then
    if [ ! ${#packagespip[@]} -eq 0 ]; then  
        echo "-----------------------------------------"
        echo "--      Installing PIP Packages        --"
        echo "-----------------------------------------"
        echo -e "${MSGCOLOUR}Installing PIP packages.....${NC}"
        pip install ${packagespip[@]}
        export PATH=/home/$user/.local/bin:$PATH
    fi
fi

if command -v code > /dev/null; then
    if [ ! ${#extensionscode[@]} -eq 0 ]; then 
        echo "-----------------------------------------"
        echo "--     Installing VSCODE Packages      --"
        echo "-----------------------------------------"
        echo -e "${MSGCOLOUR}Installing VSCode extensions.....${NC}"
        for ext in ${extensionscode[@]}; do 
            code --install-extension $ext
        done
    fi 
fi

echo "-----------------------------------------"
echo "--     Enabling Systemd Services       --"
echo "-----------------------------------------"
echo -e "${MSGCOLOUR}Enabling systemd services....${NC}"


if sudo pacman -Qs gdm > /dev/null; then
    echo -e "${MSGCOLOUR}Enabling gdm systemd service....${NC}"; 
    systemctl enable gdm.service;
fi

if sudo pacman -Qs sddm > /dev/null; then
    echo -e "${MSGCOLOUR}Enabling sddm systemd service....${NC}"; 
    systemctl enable sddm.service;
fi

if sudo pacman -Qs lightdm > /dev/null; then
    echo -e "${MSGCOLOUR}Enabling lightdm systemd service....${NC}"; 
    systemctl enable lightdm.service;
fi

if sudo pacman -Qs networkmanager > /dev/null; then
    echo -e "${MSGCOLOUR}Enabling networkmanager systemd service....${NC}"; 
    systemctl enable NetworkManager.service;
fi

if sudo pacman -Qs ufw > /dev/null; then
    echo -e "${MSGCOLOUR}Enabling ufw systemd service....${NC}"; 
    systemctl enable ufw.service;
fi

if sudo pacman -Qs apparmor > /dev/null; then
    echo -e "${MSGCOLOUR}Enabling apparmor systemd service....${NC}"; 
    systemctl enable apparmor.service;
fi