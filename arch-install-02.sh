#!/usr/bin/env bash

. /arch-install-scripts/arch-config.sh

setup_root_password(){
    msg "Setting root password....."
    until passwd
    do
        echo "Try setting root password again."
        sleep 2
    done
}

setup_user_password(){
    msg "Creating the user $user for group wheel....."
    useradd -m -G wheel $user 
    until passwd $user
    do
        echo "Try setting user password again."
        sleep 2
    done
    msg "Backing up /etc/sudoers to /etc/sudoers.bak...."
    cp /etc/sudoers /etc/sudoers.bak
    echo "$user ALL=(ALL) ALL" >> /etc/sudoers
}

encrypt_add_swap_file(){
    if [ "$encrypted" == "YES" ]; then
        msg "Adding encrypted SWAP file...."
        dd if=/dev/zero of=/swapfile bs=1M count=$swapsize status=progress
        chmod 600 /swapfile
        mkswap -L SWAP /swapfile
        swapon /swapfile
        cp /etc/fstab /etc/fstab.bak
        echo "/swapfile none swap sw 0 0" >> /etc/fstab
    fi
}

setup_local_time_and_date(){
    msg "Configuring local time and date...."
    timedatectl set-ntp true
    ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime
    hwclock --systohc
}

setup_localisation(){
    msg "Configuring localisation..."
    cp /etc/locale.gen /etc/locale.gen.bak
    sed -i "s/#${locale}.UTF-8/$locale.UTF-8/g" /etc/locale.gen
    sed -i "s/#${locale} ISO-8859-1/${locale} ISO-8859-1/g" /etc/locale.gen
    echo "LANG=$locale.UTF-8" > /etc/locale.conf
    export "LANG=$locale.UTF-8"
    locale-gen
}

setup_host_settings(){
    msg "Setting up host and hostname settings....."
    echo "$hostname" > /etc/hostname 
    echo "$host" >> /etc/hosts  
    systemctl enable NetworkManager
}

setup_grub_and_mkinitcpio(){
    if [ "$system" == "BIOS" ]; then
        msg "Installing grub bootloader and microcode....."
        pacman -S --noconfirm --needed grub $microcode os-prober
        if [ "$encrypted" == "YES" ]; then
            msg "Configuring GRUB for encrypted install....."
            cp /etc/default/grub /etc/default/grub.bak
            line='GRUB_CMDLINE_LINUX="cryptdevice=/dev/'"${drive}"'2:cr_root"'
            sed -i 's#GRUB_CMDLINE_LINUX=""#'"${line}"'#g' /etc/default/grub
            sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/g' /etc/mkinitcpio.conf
            mkinitcpio -p $kernel
        fi 
        grub-install --target=i386-pc /dev/"${drive}"
    else
        msg "Installing grub bootloader and microcode....."
        pacman -S --noconfirm --needed grub efibootmgr $microcode os-prober 
        if [ "$encrypted" == "YES" ]; then
            msg "Configuring GRUB for encrypted install....."
            cp /etc/default/grub /etc/default/grub.bak
            line='GRUB_CMDLINE_LINUX="cryptdevice=/dev/'"${drive}"'3:cr_root"'
            sed -i 's#GRUB_CMDLINE_LINUX=""#'"${line}"'#g' /etc/default/grub
            sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/g' /etc/mkinitcpio.conf
            mkinitcpio -p $kernel
        fi
        grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
    fi
    grub-mkconfig -o /boot/grub/grub.cfg   
    mkinitcpio -p $kernel 
}

cleanup_script(){
    cp -r /arch-install-scripts/ /home/$user/
    sudo chmod -R 700 /home/$user/arch-install-scripts
    sudo chown -R $user:wheel /home/$user/arch-install-scripts/
}

setup_root_password
setup_user_password
encrypt_add_swap_file

setup_local_time_and_date
setup_localisation
setup_host_settings
setup_grub_and_mkinitcpio

cleanup_script