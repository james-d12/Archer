#!/usr/bin/env bash

. /arch-install-scripts/arch-config.sh

##************************** Encrypted Install - Add SWAP ******************************##
if [ "$encrypted" == "YES" ]; then
    echo "-----------------------------------------"
    echo "--      Adding Encrypted Swap File     --"
    echo "-----------------------------------------"
    echo -e "${MSGCOLOUR}Adding encrypted SWAP file....${NC}"
    dd if=/dev/zero of=/swapfile bs=1M count=$encryptedswapsize status=progress
    chmod 600 /swapfile
    mkswap -L SWAP /swapfile
    swapon /swapfile
    echo -e "${MSGCOLOUR}Backing up /etc/fstab to /etc/fstab.bak....${NC}"
    cp /etc/fstab /etc/fstab.bak
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

echo "-----------------------------------------"
echo "--    Setting up Local Time and Date   --"
echo "-----------------------------------------"
echo -e "${MSGCOLOUR}Configuring local time and date....${NC}"
timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime
hwclock --systohc

echo "-----------------------------------------"
echo "--      Setting up Localisation        --"
echo "-----------------------------------------"
echo -e "${MSGCOLOUR}Configuring localisation...${NC}"
echo -e "${MSGCOLOUR}Creating backup /etc/locale.gen file at /etc/locale.gen.bak${NC}"
cp /etc/locale.gen /etc/locale.gen.bak
sed -i "s/#${locale}.UTF-8/$locale.UTF-8/g" /etc/locale.gen
sed -i "s/#${locale} ISO-8859-1/${locale} ISO-8859-1/g" /etc/locale.gen
echo -e "${MSGCOLOUR}Setting language in /etc/locale.conf to '$locale.UTF-8'${NC}"
echo "LANG=$locale.UTF-8" > /etc/locale.conf
export "LANG=$locale.UTF-8"
locale-gen

echo "-----------------------------------------"
echo "--      Setting up Host Settings       --"
echo "-----------------------------------------"
echo -e "${MSGCOLOUR}Setting up host and hostname settings.....${NC}"
echo "$hostname" > /etc/hostname 
echo "$host" >> /etc/hosts  


echo "-----------------------------------------"
echo "--      Setting ROOT Password          --"
echo "-----------------------------------------"
echo -e "${MSGCOLOUR}Setting root password.....${NC}"
until passwd
do
    echo "Try setting root password again."
    sleep 2
done

echo "-----------------------------------------"
echo "--  Installing Bootloader and Network  --"
echo "-----------------------------------------"
systemctl enable --now NetworkManager

# BIOS
if [ "$system" == "BIOS" ]; then
    echo -e "${MSGCOLOUR}Installing grub bootloader and microcode.....${NC}"
    pacman -S --noconfirm --needed grub $microcode os-prober
    if [ "$encrypted" == "YES" ]; then
        echo -e "${MSGCOLOUR}Configuring GRUB for encrypted install.....${NC}"
        echo -e "${MSGCOLOUR}Backing up file /etc/default/grub to /etc/default/grub.bak.....${NC}"
        cp /etc/default/grub /etc/default/grub.bak
        line='GRUB_CMDLINE_LINUX="cryptdevice=/dev/'"${drive}"'2:cr_root"'
        sed -i 's#GRUB_CMDLINE_LINUX=""#'"${line}"'#g' /etc/default/grub
        echo -e "${MSGCOLOUR}Backing up file /etc/mkinitcpio.conf to /etc/mkinitcpio.conf.bak.....${NC}"
        sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/g' /etc/mkinitcpio.conf
        mkinitcpio -p $kernel
        grub-install --target=i386-pc /dev/"${drive}"
    else
        grub-install --target=i386-pc /dev/"${drive}"
    fi
    grub-mkconfig -o /boot/grub/grub.cfg    
# UEFI
else
    echo -e "${MSGCOLOUR}Installing grub bootloader and microcode.....${NC}"
    pacman -S --noconfirm --needed grub efibootmgr $microcode os-prober 
    if [ "$encrypted" == "YES" ]; then
        echo -e "${MSGCOLOUR}Configuring GRUB for encrypted install.....${NC}"
        echo -e "${MSGCOLOUR}Backing up file /etc/default/grub to /etc/default/grub.bak.....${NC}"
        cp /etc/default/grub /etc/default/grub.bak
        line='GRUB_CMDLINE_LINUX="cryptdevice=/dev/'"${drive}"'3:cr_root"'
        sed -i 's#GRUB_CMDLINE_LINUX=""#'"${line}"'#g' /etc/default/grub
        echo -e "${MSGCOLOUR}Backing up file /etc/mkinitcpio.conf to /etc/mkinitcpio.conf.bak.....${NC}"
        sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/g' /etc/mkinitcpio.conf
        mkinitcpio -p $kernel
    fi
    grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
    grub-mkconfig -o /boot/grub/grub.cfg
    mkinitcpio -p $kernel
fi

echo "-----------------------------------------"
echo "--            Adding User              --"
echo "-----------------------------------------"
echo -e "${MSGCOLOUR}Creating the user $user for group wheel.....${NC}"
useradd -m -G wheel $user 
until passwd $user
do
    echo "Try setting user password again."
    sleep 2
done
echo -e "${MSGCOLOUR}Backing up /etc/sudoers to /etc/sudoers.bak....${NC}"
cp /etc/sudoers /etc/sudoers.bak
echo "$user ALL=(ALL) ALL" >> /etc/sudoers

echo "-----------------------------------------"
echo "--         Finishing up Script         --"
echo "-----------------------------------------"
cp -r /arch-install-scripts/ /home/$user/
sudo chmod -R 700 /home/$user/arch-install-scripts
sudo chown -R $user:wheel /home/$user/arch-install-scripts/
echo -e "${MSGCOLOUR}Reboot and run 'arch-install-03.sh'...${NC}"
