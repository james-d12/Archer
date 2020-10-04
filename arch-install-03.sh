#!/usr/bin/env bash

. resources/desktop 

check_network_connection(){
    if ! ping -c 1 -q google.com >&/dev/null; then
        echo -e "${MSGCOLOUR}You are not connected to the internet, attempting connection solutions.....${NC}"
        echo -e "${MSGCOLOUR}Attempting connection via nmtui....${NC}"
        nmtui 
        echo -e "${MSGCOLOUR}Attempting connection via wifi-menu....${NC}"
        wifi-menu
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
        "VSCODE") vscode_packages+=("$2");;
        "GIT") git_packages+=("$2");;
        *);;
    esac  
}

install_pacman_packages(){
    echo -e "${MSGCOLOUR}Installing desktop environment packages.....${NC}"
    sudo pacman -S --noconfirm --needed ${depackages[@]}
    echo -e "${MSGCOLOUR}Installing pacman packages.....${NC}"
    sudo pacman -S --noconfirm --needed ${pacman_packages[@]}   
}

install_aur_packages(){
    if ! command -v yay > /dev/null; then 
        echo -e "${MSGCOLOUR}Installing YAY.....${NC}"
        if ! command -v git > /dev/null; then 
            sudo pacman -S --noconfirm --needed git 
        fi 
        git clone https://aur.archlinux.org/yay.git
        cd yay 
        makepkg -si
    fi 
    echo -e "${MSGCOLOUR}Installing aur packages.....${NC}"
    yay -S --batchinstall --cleanafter --noconfirm --needed ${aur_packages[@]}
}

install_pip_packages(){
    if ! command -v pip > /dev/null; then 
        sudo pacman -S --noconfirm -needed python-pip 
    fi 
    echo -e "${MSGCOLOUR}Installing pip packages.....${NC}"
    pip install ${pip_packages[@]}
}

install_vscode_packages(){
    if ! command -v code > /dev/null; then 
        sudo pacman -S --noconfirm -needed code 
    fi 
    echo -e "${MSGCOLOUR}Installing vscode packages.....${NC}"
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
    if sudo pacman -Qs "$1" > /dev/null; then
        echo -e "${MSGCOLOUR}Enabling "$1" systemd service....${NC}"; 
        systemctl enable "$1".service;
    fi
}

enable_systemd_services(){
    echo -e "${MSGCOLOUR}Enabling systemd services....${NC}"
    su 
    enable_systemd_service "gdm"
    enable_systemd_service "sddm"
    enable_systemd_service "lightdm"
    enable_systemd_service "NetworkManager"
    enable_systemd_service "ufw"
    enable_systemd_service "apparmor"
    exit 
}

configure_firewall(){
    if command -v ufw > /dev/null; then
        echo -e "${MSGCOLOUR}Configuring the firewall....${NC}"
        sudo ufw limit 22/tcp  
        sudo ufw limit ssh
        sudo ufw allow 80/tcp  
        sudo ufw allow 443/tcp  
        sudo ufw default deny
        sudo ufw default deny incoming  
        sudo ufw default allow outgoing
        sudo ufw allow from 192.168.0.0/24
        sudo ufw allow Deluge
        sudo ufw enable
    fi
}

configure_sysctl(){
    if command -v sysctl > /dev/null; then
        echo -e "${MSGCOLOUR}Hardening sysctl....${NC}"
        sudo sysctl kernel.modules_disabled=1
        sudo sysctl -a
        sudo sysctl -A
        sudo sysctl mib
        sudo sysctl net.ipv4.conf.all.rp_filter
        sudo sysctl -a --pattern 'net.ipv4.conf.(eth|wlan)0.arp'
    fi
}

configure_fail2ban(){
    if command -v fail2ban > /dev/null; then
        echo -e "${MSGCOLOUR}Setting up fail2ban....${NC}"
        sudo cp fail2ban.local /etc/fail2ban/
        sudo systemctl enable fail2ban
        sudo systemctl start fail2ban
    fi
}

check_network_connection
install_packages
enable_systemd_services

configure_firewall
configure_sysctl
configure_fail2ban
