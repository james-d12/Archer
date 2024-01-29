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

function cleanup_script(){
    cp -r /arch-install-scripts/ /home/"$ARCHER_USER"/
    sudo chmod -R 700 /home/"$ARCHER_USER"/arch-install-scripts
    sudo chown -R "$ARCHER_USER:wheel" /home/"$ARCHER_USER"/arch-install-scripts/
}

echo -ne "Setting up Users:                      #                     (0%)\r"
setup_users >> logs.txt 2>&1
echo -e  "Setting up Users:                      ####################  (100%)\r"

if [ "$ARCHER_ENCRYPTED" == "YES" ]; then
    echo -ne "Adding Encrypted Swap File:            #                     (0%)\r"
    add_encrypted_swap_file >> logs.txt 2>&1
    echo -e  "Adding Encrypted Swap File:            ####################  (100%)\r"
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

cleanup_script >> logs.txt 2>&1
