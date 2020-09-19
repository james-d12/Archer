#!/usr/bin/env bash

. ./arch-config.sh

if sudo pacman -Qs ufw > /dev/null; then
    echo "-----------------------------------------"
    echo "--       Setting up Firewall           --"
    echo "-----------------------------------------"
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

if sudo pacman -Qs sysctl > /dev/null; then
    echo "-----------------------------------------"
    echo "--       Hardening Sysctl              --"
    echo "-----------------------------------------"
    sudo sysctl kernel.modules_disabled=1
    sudo sysctl -a
    sudo sysctl -A
    sudo sysctl mib
    sudo sysctl net.ipv4.conf.all.rp_filter
    sudo sysctl -a --pattern 'net.ipv4.conf.(eth|wlan)0.arp'
fi

if sudo pacman -Qs fail2ban > /dev/null; then
    echo "-----------------------------------------"
    echo "--       Setting up fail2ban           --"
    echo "-----------------------------------------"
    sudo cp fail2ban.local /etc/fail2ban/
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
fi
