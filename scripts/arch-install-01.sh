#!/usr/bin/env bash

# Arch Installer By james-d12
# GitHub Repository: https://github.com/james-d12/arch-installer

. ./arch-config.sh

wipe_drive(){
  sfdisk --delete /dev/"$drive"
}

partition_bios(){
newsize=$(($swapsize*2))
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/"$drive"
    o # clear the in memory partition table
    n # new partition
    p # primary partition
    1 # partition number 1
      # default - start at beginning of disk 
    +$newsize"M" # swap parttion
    t
    82
    n # new partition
    p # primary partition
    2 # partion number 2
      # default, start immediately after preceding partition
      # default, extend partition to end of disk
    p # print the in-memory partition table
    w # write the partition table
    q # and we're done
EOF
}

partition_bios_encrypted(){
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/"$drive"
    o # clear the in memory partition table
    n # new partition
    p # primary partition
    1 # partition number 1
      # default - start at beginning of disk 
    +512M # 512 MB boot parttion
    n # new partition
    p # primary partition
    2 # partion number 2
      # default, start immediately after preceding partition
      # default, extend partition to end of disk
    a # make a partition bootable
    1 # bootable partition is partition 1 -- /dev/sda1
    p # print the in-memory partition table
    w # write the partition table
    q # and we're done
EOF
}

partition_uefi(){
    sgdisk -Z /dev/$drive 
    sgdisk -a 2048 -o /dev/$drive 
    sgdisk -n 1:0:+512M -t 1:ef00 /dev/$drive 
    sgdisk -n 2:0:+$swapsize"M" -t 2:8200 /dev/$drive 
    sgdisk -n 3:0:0 -t 3:8300 /dev/$drive
}
partition_uefi_encrypted(){
    sgdisk -Z /dev/$drive 
    sgdisk -a 2048 -o /dev/$drive 
    sgdisk -n 1:0:+100M -t 1:ef00 /dev/$drive 
    sgdisk -n 2:0:+512M -t 2:8300 /dev/$drive 
    sgdisk -n 3:0:0 -t 3:8300 /dev/$drive 
}

format_and_mount_bios() {
    echo "Formatting and mounting for BIOS......"
    mkswap -L SWAP /dev/"${drive}1"
    mkfs.ext4 -L ROOT /dev/"${drive}2"
    swapon /dev/"${drive}1"
    mount /dev/"${drive}2" /mnt
}
format_and_mount_bios_encrypted() {
    echo "Formatting and mounting for encrypted BIOS......"
    modprobe dm-crypt && modprobe dm-mod 
    ( echo "$encryptionpass"; ) | cryptsetup luksFormat -v -s 512 -h sha512 /dev/"${drive}2"
    ( echo "$encryptionpass"; ) | cryptsetup open /dev/"${drive}2" cr_root
    mkfs.ext4 -L BOOT /dev/"${drive}1"
    mkfs.ext4 /dev/mapper/cr_root
    mount /dev/mapper/cr_root /mnt
    mkdir -p /mnt/boot
    mount /dev/"${drive}1" /mnt/boot
}
format_and_mount_uefi() {
    echo "Formatting and mounting for UEFI......"
    mkfs.fat -F32 /dev/"${drive}1"
    mkswap -L SWAP /dev/"${drive}2"
    mkfs.ext4 -L ROOT /dev/"${drive}3"
    swapon /dev/"${drive}2"
    mount /dev/"${drive}3" /mnt
    mkdir -p /mnt/boot 
    mkdir -p /mnt/boot/efi 
    mount /dev/"${drive}1" /mnt/boot/efi  
}
format_and_mount_uefi_encrypted() {
    echo "Formatting and mounting for encrypted UEFI......"
    modprobe dm-crypt && modprobe dm-mod 
    ( echo "$encryptionpass"; ) | cryptsetup luksFormat -v -s 512 -h sha512 /dev/"${drive}3"
    ( echo "$encryptionpass"; ) | cryptsetup open /dev/"${drive}3" cr_root
    mkfs.fat -F32 /dev/"${drive}1"
    mkfs.ext4 -L BOOT /dev/"${drive}2"
    mkfs.ext4 -L ROOT /dev/mapper/cr_root
    mount /dev/mapper/cr_root /mnt
    mkdir -p /mnt/boot 
    mount /dev/"${drive}2" /mnt/boot
    mkdir -p /mnt/boot/efi 
    mount /dev/"${drive}1" /mnt/boot/efi
}

wipe_drive

case "$system $encrypted" in 
     "BIOS NO") partition_bios; format_and_mount_bios;;
     "BIOS YES") partition_bios_encrypted; format_and_mount_bios_encrypted;;
     "UEFI NO") partition_uefi; format_and_mount_uefi;;
     "UEFI YES") partition_uefi_encrypted; format_and_mount_uefi_encrypted;;
esac 

pacstrap /mnt base base-devel $kernel linux-firmware nano networkmanager wireless_tools wpa_supplicant netctl dialog iwd dhclient
genfstab -U /mnt >> /mnt/etc/fstab

mkdir -p /mnt/arch-install-scripts/
cp -r * /mnt/arch-install-scripts/
arch-chroot /mnt /bin/bash -c "bash arch-install-scripts/arch-install-02.sh"

umount -R /mnt
clear 
echo "Script has finished, please shutdown, remove the USB/Installation Media and then reboot."