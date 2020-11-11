#!/usr/bin/bash 

# Arch Installer By james-d12
# GitHub Repository: https://github.com/james-d12/arch-installer

. /arch-install-scripts/arch-config.sh

setup_users(){
    useradd -m -G wheel $user 
    ( echo "$rootpass"; echo "$rootpass" ) | passwd
    ( echo "$userpass"; echo "$userpass" ) | passwd $user
    cp /etc/sudoers /etc/sudoers.bak
    echo "$user ALL=(ALL) ALL" >> /etc/sudoers
}

add_encrypted_swap_file(){
    dd if=/dev/zero of=/swapfile bs=1M count=$swapsize status=progress
    chmod 600 /swapfile
    mkswap -L SWAP /swapfile
    swapon /swapfile
    cp /etc/fstab /etc/fstab.bak
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
    genfstab -U / >> /etc/fstab
}

setup_localisation(){
    timedatectl set-ntp true
    ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime
    hwclock --systohc
    cp /etc/locale.gen /etc/locale.gen.bak
    sed -i "s/#${locale}.UTF-8/$locale.UTF-8/g" /etc/locale.gen
    sed -i "s/#${locale} ISO-8859-1/${locale} ISO-8859-1/g" /etc/locale.gen
    echo "LANG=$locale.UTF-8" > /etc/locale.conf
    export "LANG=$locale.UTF-8"
    locale-gen
}

setup_network(){
    echo "$hostname" > /etc/hostname 
    echo "$host" >> /etc/hosts  
    systemctl enable NetworkManager
}

setup_grub_bios(){
    pacman -S --noconfirm --needed grub $microcode os-prober
    if [ "$encrypted" == "YES" ]; then
        cp /etc/default/grub /etc/default/grub.bak
        line='GRUB_CMDLINE_LINUX="cryptdevice=/dev/'"${drive}"'2:cr_root"'
        sed -i 's#GRUB_CMDLINE_LINUX=""#'"${line}"'#g' /etc/default/grub
        sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/g' /etc/mkinitcpio.conf
        mkinitcpio -p $kernel
    fi 
    grub-install --target=i386-pc /dev/"${drive}"
}
setup_grub_uefi(){
    pacman -S --noconfirm --needed grub efibootmgr $microcode os-prober 
    if [ "$encrypted" == "YES" ]; then
        cp /etc/default/grub /etc/default/grub.bak 
        line='GRUB_CMDLINE_LINUX="cryptdevice=/dev/'"${drive}"'3:cr_root"'
        sed -i 's#GRUB_CMDLINE_LINUX=""#'"${line}"'#g' /etc/default/grub
        sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/g' /etc/mkinitcpio.conf
        mkinitcpio -p $kernel
    fi
    grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
}

setup_grub(){
    case "$system" in 
        "BIOS") setup_grub_bios;;
        "UEFI") setup_grub_uefi;;
    esac 
    grub-mkconfig -o /boot/grub/grub.cfg   
    mkinitcpio -p $kernel 
}

cleanup_script(){
    cp -r /arch-install-scripts/ /home/$user/
    sudo chmod -R 700 /home/$user/arch-install-scripts
    sudo chown -R $user:wheel /home/$user/arch-install-scripts/
}

echo -ne "Setting up Users:                      #                     (0%)\r"
setup_users >> logs.txt 2>&1
echo -e  "Setting up Users:                      ####################  (100%)\r"

if [ "$encrypted" == "YES" ]; then
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
echo -e  "Setting up Grub Bootloader:            #################### (100%)\r"

cleanup_script >> logs.txt 2>&1