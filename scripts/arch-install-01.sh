#!/usr/bin/bash 

# Arch Installer By james-d12
# GitHub Repository: https://github.com/james-d12/arch-installer

function setup() {
  pacman-key --init
  pacman -S --noconfirm --needed pacman-contrib
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
  rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
}

function wipe_drive(){
  umount -A --recursive /dev/$ARCHER_DRIVE
  sgdisk --zap-all /dev/"$ARCHER_DRIVE"  
  sfdisk --delete /dev/"$ARCHER_DRIVE"
  shred --verbose --random-source=/dev/urandom --iterations=1 --size=1G /dev/"$ARCHER_DRIVE"
  sync 
}

function partition_bios() {
  local newsize=$((ARCHER_SWAPSIZE * 2))
  parted -s /dev/"$ARCHER_DRIVE" mklabel msdos
  parted -s /dev/"$ARCHER_DRIVE" mkpart primary linux-swap 0% +"$newsize"M
  parted -s /dev/"$ARCHER_DRIVE" mkpart primary ext4 "$newsize"M 100%
  parted -s /dev/"$ARCHER_DRIVE" set 1 boot on
}

function partition_bios_encrypted() {
  parted -s "/dev/$ARCHER_DRIVE" mklabel msdos
  parted -s "/dev/$ARCHER_DRIVE" mkpart primary ext2 0% 512M
  parted -s "/dev/$ARCHER_DRIVE" mkpart primary ext2 512M 100%
  parted -s "/dev/$ARCHER_DRIVE" set 1 boot on
}

function partition_uefi(){
  sgdisk -Z /dev/"$ARCHER_DRIVE" 
  sgdisk -a 2048 -o /dev/"$ARCHER_DRIVE" 
  sgdisk -n 1:0:+512M -t 1:ef00 /dev/"$ARCHER_DRIVE" 
  sgdisk -n 2:0:+"${ARCHER_SWAPSIZE}M" -t 2:8200 /dev/"$ARCHER_DRIVE" 
  sgdisk -n 3:0:0 -t 3:8300 /dev/"$ARCHER_DRIVE"
}

function partition_uefi_encrypted(){
  sgdisk -Z /dev/"$ARCHER_DRIVE" 
  sgdisk -a 2048 -o /dev/"$ARCHER_DRIVE" 
  sgdisk -n 1:0:+100M -t 1:ef00 /dev/"$ARCHER_DRIVE" 
  sgdisk -n 2:0:+512M -t 2:8300 /dev/"$ARCHER_DRIVE" 
  sgdisk -n 3:0:0 -t 3:8300 /dev/"$ARCHER_DRIVE"
}

function format_and_mount_bios() {
  mkswap -L SWAP /dev/"${ARCHER_DRIVE}1"
  mkfs.ext4 -L ROOT /dev/"${ARCHER_DRIVE}2"
  swapon /dev/"${ARCHER_DRIVE}1"
  mount /dev/"${ARCHER_DRIVE}2" /mnt
}

function format_and_mount_bios_encrypted() {
  modprobe dm-crypt && modprobe dm-mod 
  ( echo "$ARCHER_ENCRYPTED_PASSWORD"; ) | cryptsetup luksFormat -v -s 512 -h sha512 /dev/"${ARCHER_DRIVE}2"
  ( echo "$ARCHER_ENCRYPTED_PASSWORD"; ) | cryptsetup open /dev/"${ARCHER_DRIVE}2" cr_root
  mkfs.ext4 -L BOOT /dev/"${ARCHER_DRIVE}1"
  mkfs.ext4 /dev/mapper/cr_root
  mount /dev/mapper/cr_root /mnt
  mkdir -p /mnt/boot
  mount /dev/"${ARCHER_DRIVE}1" /mnt/boot
}

function format_and_mount_uefi() {
  mkfs.fat -F32 /dev/"${ARCHER_DRIVE}1"
  mkswap -L SWAP /dev/"${ARCHER_DRIVE}2"
  mkfs.ext4 -L ROOT /dev/"${ARCHER_DRIVE}3"
  swapon /dev/"${ARCHER_DRIVE}2"
  mount /dev/"${ARCHER_DRIVE}3" /mnt
  mkdir -p /mnt/boot 
  mkdir -p /mnt/boot/efi 
  mount /dev/"${ARCHER_DRIVE}1" /mnt/boot/efi  
}

function format_and_mount_uefi_encrypted() {
  modprobe dm-crypt && modprobe dm-mod 
  ( echo "$ARCHER_ENCRYPTED_PASSWORD"; ) | cryptsetup luksFormat -v -s 512 -h sha512 /dev/"${ARCHER_DRIVE}3"
  ( echo "$ARCHER_ENCRYPTED_PASSWORD"; ) | cryptsetup open /dev/"${ARCHER_DRIVE}3" cr_root
  mkfs.fat -F32 /dev/"${ARCHER_DRIVE}1"
  mkfs.ext4 -L BOOT /dev/"${ARCHER_DRIVE}2"
  mkfs.ext4 -L ROOT /dev/mapper/cr_root
  mount /dev/mapper/cr_root /mnt
  mkdir -p /mnt/boot 
  mount /dev/"${ARCHER_DRIVE}2" /mnt/boot
  mkdir -p /mnt/boot/efi 
  mount /dev/"${ARCHER_DRIVE}1" /mnt/boot/efi
}

function format_and_mount(){
  case "$ARCHER_SYSTEM $ARCHER_ENCRYPTED" in 
    "BIOS NO") partition_bios; format_and_mount_bios;;
    "BIOS YES") partition_bios_encrypted; format_and_mount_bios_encrypted;;
    "UEFI NO") partition_uefi; format_and_mount_uefi;;
    "UEFI YES") partition_uefi_encrypted; format_and_mount_uefi_encrypted;;
  esac 
}

function install_base_packages(){
  pacstrap -K /mnt base base-devel $ARCHER_KERNEL linux-firmware nano networkmanager wireless_tools wpa_supplicant netctl dialog iwd dhclient
  genfstab -U /mnt >> /mnt/etc/fstab
}

function copy_files_to_mnt(){
  mkdir -p /mnt/home/$ARCHER_USER/arch-install-scripts
  cp -r ./* /mnt/home/$ARCHER_USER/arch-install-scripts
}

echo -ne "Setting up requirements:                #                     (0%)\r"
setup
echo -e  "Setting up requirements:                 ####################  (100%)\r"

echo -ne "Wiping Drive /dev/$ARCHER_DRIVE:                 #                     (0%)\r"
wipe_drive 
echo -e  "Wiping Drive /dev/$ARCHER_DRIVE:                 ####################  (100%)\r"

echo -ne "Formating and Mounting Partitions:     #                     (0%)\r"
format_and_mount 
echo -e  "Formating and Mounting Partitions:     ####################  (100%)\r"

install_base_packages 

echo -ne "Copying Files to /mnt:                 #                     (0%)\r"
copy_files_to_mnt 
echo -e  "Copying Files to /mnt:                 ####################  (100%)\r"
