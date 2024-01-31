#!/usr/bin/bash 

# Arch Installer By james-d12
# GitHub Repository: https://github.com/james-d12/arch-installer

function wipe_drive(){
  # Make sure to unmount existing drives, recursively for all partitions. 
  umount -A --recursive /dev/$ARCHER_DRIVE
  # Remove all partitions from drive
  sfdisk --delete /dev/"$ARCHER_DRIVE"
  # Sync to ensure changes to disk are synced up properly.
  sync 
}

function partition_bios() {
  local newsize=$((ARCHER_SWAPSIZE * 2))

  fdisk /dev/"$ARCHER_DRIVE" <<EOF
    o # Clear the in-memory partition table
    n # New partition
    p # Primary partition
    1 # Partition number 1
      # Default - start at the beginning of the disk 
    +$newsize"M" # Swap partition
    t
    82 # Set partition type to Linux swap
    n # New partition
    p # Primary partition
    2 # Partition number 2
      # Default, start immediately after the preceding partition
      # Default, extend partition to the end of the disk
    p # Print the in-memory partition table
    w # Write the partition table
    q # Quit
EOF
}

function partition_bios_encrypted() {
    fdisk /dev/"$ARCHER_DRIVE" <<EOF
    o # Clear the in-memory partition table
    n # New partition
    p # Primary partition
    1 # Partition number 1
      # Default - start at the beginning of the disk 
    +512M # 512 MB boot partition
    n # New partition
    p # Primary partition
    2 # Partition number 2
      # Default, start immediately after preceding partition
      # Default, extend partition to the end of the disk
    a # Make a partition bootable
    1 # Bootable partition is partition 1 -- /dev/sda1
    p # Print the in-memory partition table
    w # Write the partition table
    q # Quit
EOF
}


function partition_uefi(){
    sgdisk -Z /dev/"$ARCHER_DRIVE" 
    sgdisk -a 2048 -o /dev/"$ARCHER_DRIVE" 
    sgdisk -n 1:0:+512M -t 1:ef00 /dev/"$ARCHER_DRIVE" 
    sgdisk -n 2:0:+"${ARCHER_SWAPSIZE}M" -t 2:8200 /dev/"$ARCHER_DRIVE" 
    sgdisk -n 3:0:0 -t 3:8300 /dev/"$ARCHER_DRIVE"
    sync
}

function partition_uefi_encrypted(){
    sgdisk -Z /dev/"$ARCHER_DRIVE" 
    sgdisk -a 2048 -o /dev/"$ARCHER_DRIVE" 
    sgdisk -n 1:0:+100M -t 1:ef00 /dev/"$ARCHER_DRIVE" 
    sgdisk -n 2:0:+512M -t 2:8300 /dev/"$ARCHER_DRIVE" 
    sgdisk -n 3:0:0 -t 3:8300 /dev/"$ARCHER_DRIVE" 
    sync
}

function format_and_mount_bios() {
    mkswap -L SWAP /dev/"${ARCHER_DRIVE}1"
    mkfs.ext4 -L ROOT /dev/"${ARCHER_DRIVE}2"
    swapon /dev/"${ARCHER_DRIVE}1"
    mount /dev/"${ARCHER_DRIVE}2" /mnt
    sync
}

function format_and_mount_bios_encrypted() {
    modprobe dm-crypt && modprobe dm-mod 
    ( echo "$ARCHER_ENCRYPTED_PASSWORD"; ) | cryptsetup luksFormat -v -s 512 -h sha512 /dev/"${ARCHER_DRIVE}2"
    ( echo "$ARCHER_ENCRYPTED_PASSWORD"; ) | cryptsetup open /dev/"${ARCHER_DRIVE}2" cr_root
    mkfs.ext4 -L BOOT /dev/"${drive}1"
    mkfs.ext4 /dev/mapper/cr_root
    mount /dev/mapper/cr_root /mnt
    mkdir -p /mnt/boot
    mount /dev/"${ARCHER_DRIVE}1" /mnt/boot
    sync
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
    sync
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
    sync
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
  packages=("base" "base-devel" "$ARCHER_KERNEL" "linux-firmware" "nano" "networkmanager" "wireless_tools" "wpa_supplicant" "netctl" "dialog" "iwd" "dhclient")
  pacstrap -K /mnt ${packages[@]} 
  genfstab -U /mnt >> /mnt/etc/fstab
}

function copy_files_to_mnt(){
  mkdir -p /mnt/home/$ARCHER_USER/arch-install-scripts
  cp -r ./* /mnt/home/$ARCHER_USER/arch-install-scripts
}

echo -ne "Wiping Drive /dev/$ARCHER_DRIVE:                 #                     (0%)\r"
wipe_drive > 1
echo -e  "Wiping Drive /dev/$ARCHER_DRIVE:                 ####################  (100%)\r"

echo -ne "Formating and Mounting Partitions:     #                     (0%)\r"
format_and_mount 
echo -e  "Formating and Mounting Partitions:     ####################  (100%)\r"

install_base_packages 

echo -ne "Copying Files to /mnt:                 #                     (0%)\r"
copy_files_to_mnt 
echo -e  "Copying Files to /mnt:                 ####################  (100%)\r"
