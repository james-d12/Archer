#!/usr/bin/bash 

# This file is responsible for installing the desktop environment (if selected) and 
# to install the packages present in the resources/programs.csv file with the appropriate
# package manager.

. resources/desktop 

check_network_connection(){
    if ! ping -c 1 -q google.com >&/dev/null; then
        echo -e "You are not connected to the internet, attempting connection solutions....."
        echo -e "Attempting connection via nmtui...."
        sudo nmtui 
        echo -e "Attempting connection via wifi-menu...."
        sudo wifi-menu

        if ! ping -c 1 -q google.com >&/dev/null; then
            echo -e "Could not connect to the network, exiting script."
            exit 1 
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

warning_message(){
    echo "$1"
}

error_message(){
    echo "$1"
    exit 1
}

install_aur_helper(){
    ! command -v git >/dev/null 2>&1 && install_package git
    git clone https://aur.archlinux.org/yay.git
    cd yay && makepkg -si --noconfirm --needed
}

install_package(){
    sudo pacman -S $1 --needed --noconfirm
}

install_packages_from_lists(){
    sudo pacman -S --noconfirm --needed ${depackages[@]} || error_message "Could not install desktop environment packages, as one of the packages is invalid."
    sudo pacman -S --noconfirm --needed ${pacman_packages[@]} || error_message "Could not install pacman packages, as one of the packages is invalid."

    if [ ${#aur_packages[@]} -ne 0 ]; then
        ! command -v yay >/dev/null 2>&1 && install_aur_helper
        yay -S --batchinstall --cleanafter --noconfirm --needed ${aur_packages[@]} || error_message "Could not install AUR packages, as one of the packages is invalid."
    fi

    if [ ${#git_packages[@]} -ne 0 ]; then 
        ! command -v git >/dev/null 2>&1 && install_package git 
        for package in ${git_packages[@]}; do 
            git clone $package || warning_message "Could not clone the URL: {$package} as it is invalid."
            cd $package
            makepkg -si --noconfirm --needed;
        done 
    fi 

    if [ ! ${#pip_packages[@]} -eq 0 ]; then 
        ! command -v python-pip >/dev/null 2>&1 && install_package python-pip 
        pip install ${pip_packages[@]} || error_message "Could not install PIP packages, as one of the packages is invalid."
    fi 
    
    if [ ! ${#vscode_packages[@]} -eq 0 ]; then 
        ! command -v code >/dev/null 2>&1 && install_package code 
        code --install-extension ${vscode_packages[@]} || error_message "Could not install VSCode Extensions, as one of the extensions is invalid."
    fi 
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
    sudo systemctl enable "$1".service >/dev/null 2>&1 && echo -e "Enabling $1.service.." 
}
enable_systemd_services(){
    services=("gdm" "sddm" "lightdm" "NetworkManager" "ufw" "apparmor" "cronie")
    for service in ${services[@]}; do enable_systemd_service $service; done 
}

check_network_connection
install_packages
enable_systemd_services
