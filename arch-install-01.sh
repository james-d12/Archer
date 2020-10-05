#!/usr/bin/env bash

. ./arch-config.sh

cfdisk /dev/$drive

format_drive_uefi(){
    sgdisk -Z /dev/$drive 
    sgdisk -a 2048 -o /dev/$drive
    if [ "$encrypted" == "YES" ]; then 
        sgdisk -n 1:0:+100M -t 1:ef00 /dev/$drive 
        sgdisk -n 2:0:+512M -t 2:8300 /dev/$drive 
        sgdisk -n 3:0:0 -t 3:8300 /dev/$drive 
    else
        sgdisk -n 1:0:+100M -t 1:ef00 /dev/$drive 
        sgdisk -n 2:0:+$swapsize"M" -t 2:8200 /dev/$drive 
        sgdisk -n 3:0:0 -t 3:8300 /dev/$drive 
    fi 
}

format_drive_bios(){
    sgdisk -z /dev/$drive 
    sgdisk -a 2048 -o /dev/$drive
    if [ "$encrypted" == "YES" ]; then 
        sgdisk -n 1:0:+512M -t 1:ef02 /dev/$drive 
        sgdisk -n 2:0:0 -t 2:8300 /dev/$drive 
    else
        sgdisk -n 1:0:+$swapsize"M" -t 1:8200 /dev/$drive 
        sgdisk -n 2:0:0 -t 2:8300 /dev/$drive 
    fi 
}

format_drive(){
    if [ "$system" == "BIOS" ]; then 
        format_drive_bios
    else 
        format_drive_uefi
    fi 
}

encrypt_format_and_mount_drives(){
    modprobe dm-crypt
    modprobe dm-mod
    if [ "$system" == "BIOS" ]; then 
        echo -e "${MSGCOLOUR}Setting up cryptsetup...${NC}"
        cryptsetup luksFormat -v -s 512 -h sha512 /dev/"${drive}2"
        cryptsetup open /dev/"${drive}2" cr_root

        echo -e "${MSGCOLOUR}Formatting encrypted install partitions...${NC}"
        mkfs.ext4 -L BOOT /dev/"${drive}1"
        mkfs.ext4 /dev/mapper/cr_root

        echo -e "${MSGCOLOUR}Mounting encrypted install partitions...${NC}"
        mount /dev/mapper/cr_root /mnt
        mkdir /mnt/boot
        mount /dev/"${drive}1" /mnt/boot
    else  
        echo -e "${MSGCOLOUR}Setting up cryptsetup...${NC}"
        cryptsetup luksFormat -v -s 512 -h sha512 /dev/"${drive}3"
        cryptsetup open /dev/"${drive}3" cr_root

        echo -e "${MSGCOLOUR}Formatting encrypted install partitions...${NC}"
        mkfs.fat -F32 /dev/"${drive}1"
        mkfs.ext4 -L BOOT /dev/"${drive}2"
        mkfs.ext4 -L ROOT /dev/mapper/cr_root

        echo -e "${MSGCOLOUR}Mounting encrypted install partitions...${NC}"
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
            echo -e "${MSGCOLOUR}Formatting install partitions...${NC}"
            mkswap -L SWAP /dev/"${drive}1"
            mkfs.ext4 -L ROOT /dev/"${drive}2"

            echo -e "${MSGCOLOUR}Mounting install partitions...${NC}"
            swapon /dev/"${drive}1"
            mount /dev/"${drive}2" /mnt
        else
            echo -e "${MSGCOLOUR}Formatting install partitions...${NC}"
            mkfs.fat -F32 /dev/"${drive}1"
            mkswap -L SWAP /dev/"${drive}2"
            mkfs.ext4 -L ROOT /dev/"${drive}3"

            echo -e "${MSGCOLOUR}Mounting install partitions...${NC}"
            swapon /dev/"${drive}2"
            mount /dev/"${drive}3" /mnt
            mkdir -p /mnt/boot 
            mkdir -p /mnt/boot/efi
            mount /dev/"${drive}1" /mnt/boot/efi
        fi 
    fi 
}

install_core_packages(){
    echo -e "${MSGCOLOUR}Preparing to install core packages...${NC}"
    pacstrap /mnt base base-devel $kernel linux-firmware nano networkmanager wireless_tools wpa_supplicant netctl dialog iwd dhclient
    echo -e "${MSGCOLOUR}Generating fstab file....${NC}"
    genfstab -U /mnt >> /mnt/etc/fstab
}

chroot_into_mount_point(){
    echo -e "${MSGCOLOUR}Copying scripts to /mnt point....${NC}"
    mkdir -p /mnt/arch-install-scripts/
    cp -r * /mnt/arch-install-scripts/
    echo -e "${MSGCOLOUR}Chrooting into /mnt point....${NC}"
    arch-chroot /mnt /bin/bash -c "bash arch-install-scripts/arch-install-02.sh"
}

format_and_mount_drives
install_core_packages
chroot_into_mount_point

umount -R /mnt
reboot
