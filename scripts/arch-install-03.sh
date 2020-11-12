#!/usr/bin/bash 

# Arch Installer By james-d12
# GitHub Repository: https://github.com/james-d12/arch-installer

. "$(pwd)/resources/desktop 

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

warning() { printf "WARN: %s\n" "$1"; }
error() { printf "ERROR: %s\n" "$1"; exit 1; }

install_aur_helper(){
    ! command -v git >/dev/null 2>&1 && install_package git
    git clone https://aur.archlinux.org/yay.git
    cd yay && makepkg -si --noconfirm --needed
}

install_package(){ 
    sudo pacman -S "$1" --needed --noconfirm 
}

install_pacman_packages(){
    sudo pacman -S --noconfirm --needed "${depackages[@]}" || error "Could not install desktop environment packages, as one of the packages is invalid."
    sudo pacman -S --noconfirm --needed "${pacman_packages[@]}" || error "Could not install pacman packages, as one of the packages is invalid."
}
install_aur_packages() {
    if [ ${#aur_packages[@]} -ne 0 ]; then 
        ! command -v yay >/dev/null 2>&1 && install_aur_helper
        yay -S --batchinstall --cleanafter --noconfirm --needed "${aur_packages[@]}" || error "Could not install AUR packages, as one of the packages is invalid."
    fi 
}
install_git_packages(){
    if [ ${#git_packages[@]} -ne 0 ]; then 
        ! command -v git >/dev/null 2>&1 && install_package git 
        for package in "${git_packages[@]}"; do 
            git clone "$package" || warning "Could not clone the URL: ${package} as it is invalid."
            cd "$package" && makepkg -si --noconfirm --needed;
        done 
    fi 
}
install_pip_packages(){
    if [ ! ${#pip_packages[@]} -eq 0 ]; then 
        ! command -v python-pip >/dev/null 2>&1 && install_package python-pip 
        pip install "${pip_packages[@]}" || error "Could not install PIP packages, as one of the packages is invalid."
    fi 
}
install_vscode_packages(){
    if [ ! ${#vscode_packages[@]} -eq 0 ]; then 
        ! command -v code >/dev/null 2>&1 && install_package code 
        code --install-extension "${vscode_packages[@]}" || error "Could not install VSCode Extensions, as one of the extensions is invalid."
    fi 
}

install_packages(){
    echo -ne "      Installing Pacman packages:               #                   (0%)\r"
    install_pacman_packages
    echo -e  "      Installing Pacman packages:               ################### (100%)\r"

    echo -ne "      Installing AUR packages:                  #                   (0%)\r"
    install_aur_packages
    echo -e  "      Installing AUR packages:                  ################### (100%)\r"

    echo -ne "      Installing PIP packages:                  #                   (0%)\r"
    install_pip_packages
    echo -e  "      Installing PIP packages:                  ################### (100%)\r"
    
    echo -ne "      Installing VSCODE packages:               #                   (0%)\r"
    install_vscode_packages
    echo -e  "      Installing VSCODE packages:               ################### (100%)\r"
}

install_all_packages(){
    touch temp.csv; cat resources/programs.csv | tr -d " \t\r" > temp.csv
    while IFS=, read -r installer package description; do
        add_package_to_list "$installer" "$package" 
    done < temp.csv; 
    install_packages
    rm -rf temp.csv
}

enable_systemd_service() {  
    sudo systemctl enable "$1".service >/dev/null 2>&1 
    echo -e "Enabling $1.service.."  
}
enable_systemd_services(){
    services=("gdm" "sddm" "lightdm" "NetworkManager" "ufw" "apparmor" "cronie")
    for service in "${services[@]}"; do enable_systemd_service "$service"; done 
}

check_network_connection

echo -ne "Installing packages:                          #                   (0%)\r"
install_all_packages
echo -e "Installing packages:                          #################### (100%)\r"

echo -ne "Enabling Systemd Services:                    #                   (0%)\r"
enable_systemd_services
echo -e "Enabling Systemd Services:                   #################### (100%)\r"