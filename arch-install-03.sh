#!/usr/bin/env bash

. resources/desktop 

check_network_connection(){
    if ! ping -c 1 -q google.com >&/dev/null; then
        echo -e "You are not connected to the internet, attempting connection solutions....."
        echo -e "Attempting connection via nmtui...."
        sudo nmtui 
        echo -e "Attempting connection via wifi-menu...."
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

install_dependencies(){
    sudo pacman -S --noconfirm --needed git python-pip code 
    git clone https://aur.archlinux.org/yay.git
    cd yay && makepkg -si --noconfirm --needed
}

install_package(){
    sudo pacman -S $1 --needed --noconfirm
}

install_packages_from_lists(){
    sudo pacman -S --noconfirm --needed ${depackages[@]}
    sudo pacman -S --noconfirm --needed ${pacman_packages[@]} 
    yay -S --batchinstall --cleanafter --noconfirm --needed ${aur_packages[@]}
    pip install ${pip_packages[@]} || install_package python-pip >/dev/null 2>&1 && pip install ${pip_packages[@]]}
    code --install-extension ${vscode_packages[@]} || install_package code >/dev/null 2>&1 && code --install-extension ${vscode_packages[@]} 
    for package in ${git_packages[@]}; do 
        git clone $package $package; 
        cd $package; 
        makepkg -si --noconfirm --needed; 
    done 
}

install_packages(){
    touch temp.csv; cat resources/programs.csv | tr -d " \t\r" > temp.csv
    while IFS=, read -r installer package; do
        add_package_to_list $installer $package 
    done < temp.csv; 
    install_packages_from_lists
    rm -rf temp.csv
}

enable_systemd_service(){ sudo systemctl enable "$1".service >/dev/null 2>&1 && echo -e "Enabling $1.service.." }
enable_systemd_services(){
    services=("gdm" "sddm" "lightdm" "NetworkManager" "ufw" "apparmor")
    for service in ${services[@]}; do enable_systemd_service $service; done 
}

check_network_connection
install_packages
enable_systemd_services