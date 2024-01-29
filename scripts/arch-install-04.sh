#!/usr/bin/bash 

# Arch Installer By james-d12
# GitHub Repository: https://github.com/james-d12/arch-installer

function restrict_kernel_log_access() { 
    echo "kernel.dmesg_restrict = 1" >> /etc/sysctl.d/51-dmesg-restrict.conf 
}

function increase_user_login_timeout() { 
    echo "auth optional pam_faildelay.so delay=4000000" >> /etc/pam.d/system-login 
}

function deny_ip_spoofs(){ 
    printf "order bind, hosts\n multi on" >> /etc/host.conf 
}

function configure_apparmor_and_firejail(){
    command -v firejail > /dev/null && command -v apparmor > /dev/null &&
    firecfg && sudo apparmor_parser -r /etc/apparmor.d/firejail-default
}

function configure_firewall(){
    if command -v ufw > /dev/null; then
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

function configure_sysctl(){
    if command -v sysctl > /dev/null; then
        sudo sysctl -a
        sudo sysctl -A
        sudo sysctl mib
        sudo sysctl net.ipv4.conf.all.rp_filter
        sudo sysctl -a --pattern 'net.ipv4.conf.(eth|wlan)0.arp'
    fi
}

function configure_fail2ban(){
    if command -v fail2ban > /dev/null; then
        sudo cp fail2ban.local /etc/fail2ban/
        sudo systemctl enable fail2ban
        sudo systemctl start fail2ban
    fi
}

su "$ARCHER_USER"

restrict_kernel_log_access
increase_user_login_timeout
deny_ip_spoofs
configure_firewall
configure_sysctl
configure_fail2ban
configure_apparmor_and_firejail