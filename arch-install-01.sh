#!/usr/bin/bash 

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
    mkswap -L SWAP /dev/"${drive}1"
    mkfs.ext4 -L ROOT /dev/"${drive}2"
    swapon /dev/"${drive}1"
    mount /dev/"${drive}2" /mnt
}
format_and_mount_bios_encrypted() {
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

format_and_mount(){
  case "$system $encrypted" in 
       "BIOS NO") partition_bios; format_and_mount_bios;;
       "BIOS YES") partition_bios_encrypted; format_and_mount_bios_encrypted;;
       "UEFI NO") partition_uefi; format_and_mount_uefi;;
       "UEFI YES") partition_uefi_encrypted; format_and_mount_uefi_encrypted;;
  esac 
}

install_base_packages(){
  packages=("base" "base-devel" "$kernel" "linux-firmware" "nano" "networkmanager" "wireless_tools" "wpa_supplicant" "netctl" "dialog" "iwd" "dhclient")
  for pkg in ${packages[@]}; do 
    echo "    Installing $pkg: #                     (0%)" 
    pacstrap /mnt $pkg >/dev/null 2>&1
    echo "    Installing $pkg: ##################### (100%)" 
  done 
  genfstab -U /mnt >> /mnt/etc/fstab
}

copy_files_to_mnt(){
  mkdir -p /mnt/arch-install-scripts/
  cp -r * /mnt/arch-install-scripts/
}

echo "Wiping Drive /dev/$drive:                 #                     (0%)"
wipe_drive > logs.txt 2>&1
echo -ne "Wiping Drive /dev/$drive:                 ####################  (100%)\r\n"

echo -ne "Formating and Mounting Partitions:     #                     (0%)"
format_and_mount >> logs.txt 2>&1
echo -ne "Formating and Mounting Partitions:     ####################  (100%)\r\n"

echo -ne "Installing Base Packages:              #                     (0%)"
install_base_packages 
echo -ne "Installing Base Packages:              ####################  (100%)\r\n"

echo -ne "Copying Files to /mnt:                 #                     (0%)"
copy_files_to_mnt >> logs.txt 2>&1
echo -ne "Copying Files to /mnt:                 ####################  (100%)\r\n"

arch-chroot /mnt /bin/bash -c "bash arch-install-scripts/arch-install-02.sh"

umount -R /mnt
echo -ne "Script has finished, please shutdown, remove the USB/Installation Media and then reboot."