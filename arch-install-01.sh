#!/usr/bin/env bash

. ./arch-config.sh

echo "-----------------------------------------"
echo "--      Drive Format and Mounting      --"
echo "-----------------------------------------"
# BIOS SYSTEM
if [ "$system" == "BIOS" ]; then
    if [ "$encrypted" == "YES" ]; then
        echo -e "${MSGCOLOUR}Setting up cryptsetup...${NC}"
        modprobe dm-crypt
        modprobe dm-mod
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
        echo -e "${MSGCOLOUR}Formatting install partitions...${NC}"
        mkswap -L SWAP /dev/"${drive}1"
        mkfs.ext4 -L ROOT /dev/"${drive}2"
        
        echo -e "${MSGCOLOUR}Mounting install partitions...${NC}"
        swapon /dev/"${drive}1"
        mount /dev/"${drive}2" /mnt
    fi
# UEFI System
else 
    if [ "$encrypted" == "YES" ]; then
        echo -e "${MSGCOLOUR}Setting up cryptsetup...${NC}"
        modprobe dm-crypt
        modprobe dm-mod
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

echo "-----------------------------------------"
echo "--      Installing Core Packages       --"
echo "-----------------------------------------"
echo -e "${MSGCOLOUR}Preparing to install core packages...${NC}"
pacstrap /mnt base base-devel $kernel linux-firmware nano networkmanager wireless_tools wpa_supplicant netctl dialog iwd dhclient
echo -e "${MSGCOLOUR}Generating fstab file....${NC}"
genfstab -U /mnt >> /mnt/etc/fstab

echo "-----------------------------------------"
echo "--     Chrooting Into Mount Point     --"
echo "-----------------------------------------"
echo -e "${MSGCOLOUR}Copying scripts to /mnt point....${NC}"
mkdir -p /mnt/arch-install-scripts/
cp -r * /mnt/arch-install-scripts/
echo -e "${MSGCOLOUR}Chrooting into /mnt point....${NC}"
arch-chroot /mnt /bin/bash -c "bash arch-install-scripts/arch-install-02.sh"
