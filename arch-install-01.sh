#!/usr/bin/env bash

. ./arch-config.sh

format_and_mount_bios() {
    mkswap -L SWAP /dev/"${drive}1"
    mkfs.ext4 -L ROOT /dev/"${drive}2"
    swapon /dev/"${drive}1"
    mount /dev/"${drive}2" /mnt
}
format_and_mount_bios_encrypted() {
    modprobe dm-crypt && modprobe dm-mod 
    cryptsetup luksFormat -v -s 512 -h sha512 /dev/"${drive}2"
    cryptsetup open /dev/"${drive}2" cr_root
    mkfs.ext4 -L BOOT /dev/"${drive}1"
    mkfs.ext4 /dev/mapper/cr_root
    mount /dev/mapper/cr_root /mnt
    mkdir /mnt/boot
    mount /dev/"${drive}1" /mnt/boot
}
format_and_mount_uefi() {
    mkfs.fat -F32 /dev/"${drive}1"
    mkswap -L SWAP /dev/"${drive}2"
    mkfs.ext4 -L ROOT /dev/"${drive}3"
    swapon /dev/"${drive}2"
    mount /dev/"${drive}3" /mnt
    mkdir -p /mnt/boot/efi
    mount /dev/"${drive}1" /mnt/boot/efi  
}
format_and_mount_uefi_encrypted() {
    modprobe dm-crypt && modprobe dm-mod 
    cryptsetup luksFormat -v -s 512 -h sha512 /dev/"${drive}3"
    cryptsetup open /dev/"${drive}3" cr_root
    mkfs.fat -F32 /dev/"${drive}1"
    mkfs.ext4 -L BOOT /dev/"${drive}2"
    mkfs.ext4 -L ROOT /dev/mapper/cr_root
    mount /dev/mapper/cr_root /mnt
    mkdir -p /mnt/boot/efi
    mount /dev/"${drive}2" /mnt/boot
    mount /dev/"${drive}1" /mnt/boot/efi
}

cfdisk /dev/$drive

case "$system $encrypted" in 
     "BIOS NO") format_and_mount_bios;;
     "BIOS YES") format_and_mount_bios_encrypted
     "UEFI NO") format_and_mount_uefi
     "UEFI YES") format_and_mount_uefi_encrypted
esac 

pacstrap /mnt base base-devel $kernel linux-firmware nano networkmanager wireless_tools wpa_supplicant netctl dialog iwd dhclient
genfstab -U /mnt >> /mnt/etc/fstab

mkdir -p /mnt/arch-install-scripts/
cp -r * /mnt/arch-install-scripts/
arch-chroot /mnt /bin/bash -c "bash ./arch-install-02.sh"

umount -R /mnt
reboot