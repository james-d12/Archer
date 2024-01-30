#!/usr/bin/bash 

# Arch Installer By james-d12
# GitHub Repository: https://github.com/james-d12/arch-installer

function setup_users(){
    useradd -m -G wheel "$ARCHER_USER" 
    ( echo "$ARCHER_ROOT_PASSWORD"; echo "$ARCHER_ROOT_PASSWORD" ) | passwd
    ( echo "$ARCHER_USER_PASSWORD"; echo "$ARCHER_USER_PASSWORD" ) | passwd "$ARCHER_USER"
    cp /etc/sudoers /etc/sudoers.bak
    echo "$ARCHER_USER ALL=(ALL) ALL" >> /etc/sudoers
}

function add_encrypted_swap_file(){
    dd if=/dev/zero of=/swapfile bs=1M count="$ARCHER_SWAPSIZE" status=progress
    chmod 600 /swapfile
    mkswap -L SWAP /swapfile
    swapon /swapfile
    cp /etc/fstab /etc/fstab.bak
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
    genfstab -U / >> /etc/fstab
}

function setup_localisation(){
    timedatectl set-ntp true
    ln -sf /usr/share/zoneinfo/"$ARCHER_REGION"/"$ARCHER_CITY" /etc/localtime
    hwclock --systohc
    cp /etc/locale.gen /etc/locale.gen.bak
    sed -i "s/#${ARCHER_LOCALE}.UTF-8/$ARCHER_LOCALE.UTF-8/g" /etc/locale.gen
    sed -i "s/#${ARCHER_LOCALE} ISO-8859-1/${ARCHER_LOCALE} ISO-8859-1/g" /etc/locale.gen
    echo "LANG=$ARCHER_LOCALE.UTF-8" > /etc/locale.conf
    export "LANG=$ARCHER_LOCALE.UTF-8"
    locale-gen
}

function setup_network(){
    echo "$ARCHER_HOSTNAME" > /etc/hostname 
    echo "$ARCHER_HOST" >> /etc/hosts  
    systemctl enable NetworkManager
}

function setup_grub_bios(){
    pacman -S --noconfirm --needed grub "$ARCHER_MICROCODE" os-prober
    if [ "$ARCHER_ENCRYPTED" == "YES" ]; then
        cp /etc/default/grub /etc/default/grub.bak
        local line='GRUB_CMDLINE_LINUX="cryptdevice=/dev/'"${ARCHER_DRIVE}"'2:cr_root"'
        sed -i 's#GRUB_CMDLINE_LINUX=""#'"${line}"'#g' /etc/default/grub
        sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/g' /etc/mkinitcpio.conf
        mkinitcpio -p "$ARCHER_KERNEL"
    fi 
    grub-install --target=i386-pc /dev/"${ARCHER_DRIVE}"
}

function setup_grub_uefi(){
    pacman -S --noconfirm --needed grub efibootmgr "$ARCHER_MICROCODE" os-prober 
    if [ "$ARCHER_ENCRYPTED" == "YES" ]; then
        cp /etc/default/grub /etc/default/grub.bak 
        local line='GRUB_CMDLINE_LINUX="cryptdevice=/dev/'"${ARCHER_DRIVE}"'3:cr_root"'
        sed -i 's#GRUB_CMDLINE_LINUX=""#'"${line}"'#g' /etc/default/grub
        sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/g' /etc/mkinitcpio.conf
        mkinitcpio -p "$ARCHER_KERNEL"
    fi
    grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
}

function setup_grub(){
    case "$ARCHER_SYSTEM" in 
        "BIOS") setup_grub_bios;;
        "UEFI") setup_grub_uefi;;
    esac 
    grub-mkconfig -o /boot/grub/grub.cfg   
    mkinitcpio -p "$ARCHER_KERNEL" 
}

function check_network_connection(){
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

function add_package_to_list(){
    case "$1" in 
        "PACMAN") pacman_packages+=("$2");;
        "AUR") aur_packages+=("$2");;
        "PIP") pip_packages+=("$2");;
        "GIT") git_packages+=("$2");;
        *);;
    esac  
}

function warning() { printf "WARN: %s\n" "$1"; }
function error() { printf "ERROR: %s\n" "$1"; exit 1; }

function install_aur_helper(){
    ! command -v git >/dev/null 2>&1 && install_package git
    git clone https://aur.archlinux.org/yay.git
    cd yay && makepkg -si --noconfirm --needed
}

function install_package(){ 
    sudo pacman -S "$1" --needed --noconfirm 
}

function install_pacman_packages(){
    sudo pacman -S --noconfirm --needed "${depackages[@]}" || error "Could not install desktop environment packages, as one of the packages is invalid."
    sudo pacman -S --noconfirm --needed "${pacman_packages[@]}" || error "Could not install pacman packages, as one of the packages is invalid."
}

function install_aur_packages() {
    if [ ${#aur_packages[@]} -ne 0 ]; then 
        ! command -v yay >/dev/null 2>&1 && install_aur_helper
        yay -S --batchinstall --cleanafter --noconfirm --needed "${aur_packages[@]}" || error "Could not install AUR packages, as one of the packages is invalid."
    fi 
}

function install_git_packages(){
    if [ ${#git_packages[@]} -ne 0 ]; then 
        ! command -v git >/dev/null 2>&1 && install_package git 
        for package in "${git_packages[@]}"; do 
            git clone "$package" || warning "Could not clone the URL: ${package} as it is invalid."
            cd "$package" && makepkg -si --noconfirm --needed;
        done 
    fi 
}

function install_pip_packages(){
    if [ ! ${#pip_packages[@]} -eq 0 ]; then 
        ! command -v python-pip >/dev/null 2>&1 && install_package python-pip 
        pip install "${pip_packages[@]}" || error "Could not install PIP packages, as one of the packages is invalid."
    fi 
}

function install_vscode_packages(){
    if [ ! ${#vscode_packages[@]} -eq 0 ]; then 
        ! command -v code >/dev/null 2>&1 && install_package code 
        code --install-extension "${vscode_packages[@]}" || error "Could not install VSCode Extensions, as one of the extensions is invalid."
    fi 
}

function install_packages(){
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

function install_all_packages(){
    touch temp.csv; 
    "/home/$ARCHER_USER/arch-install-scripts/resources/programs.csv" | tr -d " \t\r" > temp.csv
    while IFS=, read -r installer package description; do
        add_package_to_list "$installer" "$package" 
    done < temp.csv; 
    install_packages
    rm -rf temp.csv
}

function enable_systemd_service() {  
    sudo systemctl enable "$1".service >/dev/null 2>&1 
    echo -e "Enabling $1.service.."  
}

function enable_systemd_services(){
    services=("gdm" "sddm" "lightdm" "NetworkManager" "ufw" "apparmor" "cronie")
    for service in "${services[@]}"; do enable_systemd_service "$service"; done 
}

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

echo -ne "Setting up Users:                      #                     (0%)\r"
setup_users >> logs.txt 2>&1
echo -e  "Setting up Users:                      ####################  (100%)\r"

if [ "$ARCHER_ENCRYPTED" == "YES" ]; then
    echo -ne "Setting up Encrypted Swap File:        #                     (0%)\r"
    add_encrypted_swap_file >> logs.txt 2>&1
    echo -e  "Setting up Encrypted Swap File:        ####################  (100%)\r"
fi 

echo -ne "Setting up Localisation:               #                     (0%)\r"
setup_localisation >> logs.txt 2>&1
echo -e  "Setting up Localisation:               ####################  (100%)\r"

echo -ne "Setting up Network:                    #                     (0%)\r"
setup_network >> logs.txt 2>&1
echo -e  "Setting up Network:                    ####################  (100%)\r"

echo -ne "Setting up Grub Bootloader:            #                     (0%)\r"
setup_grub >> logs.txt 2>&1
echo -e  "Setting up Grub Bootloader:            ####################  (100%)\r"

echo -ne "Checking Network:                          #                   (0%)\r"
check_network_connection
echo -e "Checking Network:                          #################### (100%)\r"

echo -ne "Installing packages:                          #                   (0%)\r"
install_all_packages
echo -e "Installing packages:                          #################### (100%)\r"

echo -ne "Enabling Systemd Services:                    #                   (0%)\r"
enable_systemd_services
echo -e "Enabling Systemd Services:                   #################### (100%)\r"

echo -ne "Restricted Kernel Log Access                  #                   (0%)\r"
restrict_kernel_log_access
echo -e "Restricted Kernel Log Access                  #################### (100%)\r"

echo -ne "Increasing User Login Timeout                  #                   (0%)\r"
increase_user_login_timeout
echo -e "Increasing User Login Timeout                  #################### (100%)\r"

echo -ne "Denying IP Spoofs                  #                   (0%)\r"
deny_ip_spoofs
echo -e "Denying IP Spoofs                  #################### (100%)\r"

echo -ne "Configuring Firewall                  #                   (0%)\r"
configure_firewall
echo -e "Configuring Firewall                  #################### (100%)\r"

echo -ne "Configuring sysctl                  #                   (0%)\r"
configure_sysctl
echo -e "Configuring sysctl                  #################### (100%)\r"

echo -ne "Configuring Fail2Ban                  #                   (0%)\r"
configure_fail2ban
echo -e "Configuring Fail2Ban                  #################### (100%)\r"

echo -ne "Configuring Apparmor & Firejail                  #                   (0%)\r"
configure_apparmor_and_firejail
echo -e "Configuring Apparmor & Firejail                  #################### (100%)\r"