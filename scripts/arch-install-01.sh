#!/usr/bin/bash 

# Arch Installer By james-d12
# GitHub Repository: https://github.com/james-d12/arch-installer

function wipe_drive(){
  sfdisk --delete /dev/"$drive"
}

function partition_bios(){
newsize=$((ARCHER_SWAPSIZE*2))
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/"$ARCHER_DRIVE"
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

function partition_bios_encrypted(){
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/"$ARCHER_DRIVE"
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
    mkfs.ext4 -L BOOT /dev/"${drive}1"
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
  packages=("base" "base-devel" "$ARCHER_KERNEL" "linux-firmware" "nano" "networkmanager" "wireless_tools" "wpa_supplicant" "netctl" "dialog" "iwd" "dhclient")
  echo "Installing Base Packages:"
  for pkg in "${packages[@]}"; do 
    echo -ne "    Installing ""$pkg"": #                     (0%)\r" 
    pacstrap -K /mnt "$pkg" >/dev/null 2>&1
    echo -e  "    Installing ""$pkg"": ##################### (100%)\r" 
  done 
  genfstab -U /mnt >> /mnt/etc/fstab
}

function copy_files_to_mnt(){
  mkdir -p /mnt/arch-install-scripts/
  cp -r ./* /mnt/arch-install-scripts/
}


echo "Environment Variables"
echo "drive=""${ARCHER_DRIVE}""
encrypted=""${ARCHER_ENCRYPTED}""
encryptionpass=""${ARCHER_ENCRYPTED_PASSWORD}""
swapsize=""${ARCHER_SWAPSIZE}""
system=""${ARCHER_SYSTEM}"" 
kernel=""${ARCHER_KERNEL}""
microcode=""${ARCHER_MICROCODE}""
desktopenvironment=""${ARCHER_DESKTOPENVIRONMENT}""
user=""${ARCHER_USER}""
userpass=""${ARCHER_USER_PASSWORD}""
rootpass=""${ARCHER_ROOT_PASSWORD}""
locale=""${ARCHER_LOCALE}""
region=""${ARCHER_REGION}""
city=""${ARCHER_CITY}""
hostname=""${ARCHER_HOSTNAME}"""
echo "***********************************"


echo -ne "Wiping Drive /dev/$ARCHER_DRIVE:                 #                     (0%)\r"
wipe_drive > logs.txt 2>&1
echo -e  "Wiping Drive /dev/$ARCHER_DRIVE:                 ####################  (100%)\r"

echo -ne "Formating and Mounting Partitions:     #                     (0%)\r"
format_and_mount >> logs.txt 2>&1
echo -e  "Formating and Mounting Partitions:     ####################  (100%)\r"

install_base_packages 

echo -ne "Copying Files to /mnt:                 #                     (0%)\r"
copy_files_to_mnt >> logs.txt 2>&1
echo -e  "Copying Files to /mnt:                 ####################  (100%)\r"
