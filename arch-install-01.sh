#!/usr/bin/env bash

. ./arch-config.sh

cfdisk /dev/$drive

encrypt_format_and_mount_drives(){
    modprobe dm-crypt
    modprobe dm-mod
    if [ "$system" == "BIOS" ]; then 
        msg "Setting up cryptsetup..."
        cryptsetup luksFormat -v -s 512 -h sha512 /dev/"${drive}2"
        cryptsetup open /dev/"${drive}2" cr_root

        msg "Formatting encrypted install partitions..."
        mkfs.ext4 -L BOOT /dev/"${drive}1"
        mkfs.ext4 /dev/mapper/cr_root

        msg "Mounting encrypted install partitions..."
        mount /dev/mapper/cr_root /mnt
        mkdir /mnt/boot
        mount /dev/"${drive}1" /mnt/boot
    else  
        msg "Setting up cryptsetup..."
        cryptsetup luksFormat -v -s 512 -h sha512 /dev/"${drive}3"
        cryptsetup open /dev/"${drive}3" cr_root

        msg "Formatting encrypted install partitions..."
        mkfs.fat -F32 /dev/"${drive}1"
        mkfs.ext4 -L BOOT /dev/"${drive}2"
        mkfs.ext4 -L ROOT /dev/mapper/cr_root

        msg "Mounting encrypted install partitions..."
        mount /dev/mapper/cr_root /mnt
        mkdir -p /mnt/boot
        mount /dev/"${drive}2" /mnt/boot
        mkdir -p /mnt/boot/efi
        mount /dev/"${drive}1" /mnt/boot/efi
    fi 
}

format_and_mount_drives(){
    if [ "$encrypted" == "YES" ]; then
        encrypt_format_and_mount_drives 
    else 
        if [ "$system" == "BIOS" ]; then
            msg "Formatting install partitions..."
            mkswap -L SWAP /dev/"${drive}1"
            mkfs.ext4 -L ROOT /dev/"${drive}2"

            msg "Mounting install partitions..."
            swapon /dev/"${drive}1"
            mount /dev/"${drive}2" /mnt
        else
            msg "Formatting install partitions..."
            mkfs.fat -F32 /dev/"${drive}1"
            mkswap -L SWAP /dev/"${drive}2"
            mkfs.ext4 -L ROOT /dev/"${drive}3"

            msg "Mounting install partitions..."
            swapon /dev/"${drive}2"
            mount /dev/"${drive}3" /mnt
            mkdir -p /mnt/boot 
            mkdir -p /mnt/boot/efi
            mount /dev/"${drive}1" /mnt/boot/efi
        fi 
    fi 
}

install_core_packages(){
    msg "Preparing to install core packages..."
    pacstrap /mnt base base-devel $kernel linux-firmware nano networkmanager wireless_tools wpa_supplicant netctl dialog iwd dhclient
    msg "Generating fstab file...."
    genfstab -U /mnt >> /mnt/etc/fstab
}

chroot_into_mount_point(){
    msg "Copying scripts to /mnt point...."
    mkdir -p /mnt/arch-install-scripts/
    cp -r * /mnt/arch-install-scripts/
    msg "Chrooting into /mnt point...."
    arch-chroot /mnt /bin/bash -c "bash arch-install-scripts/arch-install-02.sh"
}

format_and_mount_drives
install_core_packages
chroot_into_mount_point

umount -R /mnt
reboot
