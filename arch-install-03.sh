#!/usr/bin/env bash

. resources/desktop 

check_network_connection(){
    if ! ping -c 1 -q google.com >&/dev/null; then
        msg "You are not connected to the internet, attempting connection solutions....."
        msg "Attempting connection via nmtui...."
        sudo nmtui 
        msg "Attempting connection via wifi-menu...."
        sudo wifi-menu
    fi
}

pacman_packages=()
aur_packages=()
pip_packages=()
git_packages=()
vscode_packages=()

add_package_to_list(){
    case "$1" in
        "PACMAN") pacman_packages+=("$2");;
        "AUR") aur_packages+=("$2");;
        "PIP") pip_packages+=("$2");;
        "GIT") git_packages+=("$2");;
        *);;
    esac  
}

install_pacman_packages(){
    msg "Installing desktop environment packages....."
    sudo pacman -S --noconfirm --needed ${depackages[@]}
    msg "Installing pacman packages....."
    sudo pacman -S --noconfirm --needed ${pacman_packages[@]}   
}

install_aur_packages(){
    if ! command -v yay > /dev/null; then 
        msg "Installing YAY....."
        if ! command -v git > /dev/null; then 
            sudo pacman -S --noconfirm --needed git 
        fi 
        git clone https://aur.archlinux.org/yay.git
        cd yay 
        makepkg -si
    fi 
    msg "Installing aur packages....."
    yay -S --batchinstall --cleanafter --noconfirm --needed ${aur_packages[@]}
}

install_pip_packages(){
    if ! command -v pip > /dev/null; then 
        sudo pacman -S --noconfirm --needed python-pip 
    fi 
    msg "Installing pip packages....."
    pip install ${pip_packages[@]}
}

install_git_packages(){
    if ! command -v git > /dev/null; then 
        sudo pacman -S --noconfirm --needed git 
    fi 
    for package in ${git_packages[@]}; do 
        git clone $package $package 
        cd $package 
        makepkg -si 
    done 
}

install_vscode_packages(){
    if ! command -v code > /dev/null; then 
        sudo pacman -S --noconfirm --needed code 
    fi 
    msg "Installing vscode packages....."
    code --install-extension ${vscode_packages[@]}
}

install_packages_from_lists(){
    install_pacman_packages
    install_aur_packages
    install_pip_packages
    install_vscode_packages
}

install_packages(){
    touch temp.csv; cat resources/programs.csv | tr -d " \t\r" > temp.csv
    while IFS=, read -r installer package description; do
        add_package_to_list $installer $package 
    done < temp.csv; 
    install_packages_from_lists
    rm -rf temp.csv
}

enable_systemd_service(){
    sudo systemctl enable "$1".service >/dev/null 2>&1 && msg "Enabling $1 systemd service...." 
}

enable_systemd_services(){
    enable_systemd_service "gdm"
    enable_systemd_service "sddm"
    enable_systemd_service "lightdm"
    enable_systemd_service "NetworkManager"
    enable_systemd_service "ufw"
    enable_systemd_service "apparmor"
}

check_network_connection
install_packages
enable_systemd_services