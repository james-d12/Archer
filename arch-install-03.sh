#!/usr/bin/env bash

. ./arch-config.sh

check_network_connection(){
    if ! ping -c 1 -q google.com >&/dev/null; then
        echo -e "${MSGCOLOUR}You are not connected to the internet, attempting connection solutions.....${NC}"
        echo -e "${MSGCOLOUR}Attempting connection via nmtui....${NC}"
        nmtui 
        echo -e "${MSGCOLOUR}Attempting connection via wifi-menu....${NC}"
        wifi-menu
    fi
}


install_package(){
    case "$1" in
        "PACMAN") 
            sudo pacman -S "$2" --needed --noconfirm;;
        "AUR")
            if ! command -v yay > /dev/null; then 
                echo -e "${MSGCOLOUR}Installing YAY.....${NC}"
                git clone https://aur.archlinux.org/yay.git
                cd yay 
                makepkg -si
            fi  
            yay -S --cleanafter --noconfirm --needed "$2";;
        "PIP") 
            if ! command -v pip > /dev/null; then 
                sudo pacman -S --needed --noconfirm python-pip
            fi 
            pip install "$2";;
        "VSCODE") 
            if ! command -v code > /dev/null; then 
                sudo pacman -S --needed --noconfirm code 
            fi 
            code --install-extension "$2";;
        *);;
    esac  
}

install_packages(){
    echo -e "${MSGCOLOUR}Installing desktop environment packages.....${NC}"
    sudo pacman -S --noconfirm --needed ${depackages[@]}

    echo -e "${MSGCOLOUR}Installing individual packages.....${NC}"
    touch temp.csv; cat resources/programs.csv | tr -d " \t\r" > temp.csv
    while IFS=, read -r installer package description; do
        install_package $installer $package 
    done < temp.csv; 
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
    enable_systemd_service "gdm"
    enable_systemd_service "sddm"
    enable_systemd_service "lightdm"
    enable_systemd_service "NetworkManager"
    enable_systemd_service "ufw"
    enable_systemd_service "apparmor"
}

configure_firewall(){
    if sudo pacman -Qs ufw > /dev/null; then
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
    if sudo pacman -Qs sysctl > /dev/null; then
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
    if sudo pacman -Qs fail2ban > /dev/null; then
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
