#!/usr/bin/env bash

. /arch-install-scripts/arch-config.sh

setup_users(){
    useradd -m -G wheel $user 
    until passwd; do echo "Try setting root password again."; sleep 2; done
    until passwd $user; do echo "Try setting user password again."; sleep 2; done
    cp /etc/sudoers /etc/sudoers.bak
    echo "$user ALL=(ALL) ALL" >> /etc/sudoers
}

add_encrypted_swap_file(){
    if [ "$encrypted" == "YES" ]; then
        dd if=/dev/zero of=/swapfile bs=1M count=$swapsize status=progress
        chmod 600 /swapfile
        mkswap -L SWAP /swapfile
        swapon /swapfile
        cp /etc/fstab /etc/fstab.bak
        echo "/swapfile none swap sw 0 0" >> /etc/fstab
    fi
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

setup_users
add_encrypted_swap_file
setup_localisation
setup_network
setup_grub
cleanup_script