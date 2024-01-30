#!/usr/bin/bash 

# Arch Installer By james-d12
# GitHub Repository: https://github.com/james-d12/arch-installer

function print_home(){
    echo "------------------------------------------------"
    echo " █████╗ ██████╗  ██████╗██╗  ██╗███████╗██████╗"
    echo "██╔══██╗██╔══██╗██╔════╝██║  ██║██╔════╝██╔══██╗ "
    echo "███████║██████╔╝██║     ███████║█████╗  ██████╔╝"
    echo "██╔══██║██╔══██╗██║     ██╔══██║██╔══╝  ██╔══██╗"
    echo "██║  ██║██║  ██║╚██████╗██║  ██║███████╗██║  ██║"
    echo "╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
    echo "          Made by James Durban"
    echo "GitHub Repository: https://github.com/james-d12/archer"
    echo "------------------------------------------------" 
}

function get_user_input(){
    clear
    
    print_home
    PS3='Encrypt Drive?'
    options=("YES" "NO")
    select o  in "${options[@]}"; do
        case $o in
            "YES") encrypted=$o; break;;
            "NO") encrypted=$o; break;;
            *) echo "Invalid option $REPLY";;
        esac
    done

    if [ "$encrypted" == "YES" ]; then 
        read -r -s -p "Enter encryption password: " pass1; echo ''
        read -r -s -p "Re-enter encryption password: " pass2; echo ''
        while [[ "$pass1" != "$pass2" || -z "$pass1" ]]; do
            echo "Passwords do not match, please retry."
            read -r -s -p "Enter encryption password: " pass1; echo ''
            read -r -s -p "Re-enter encryption password: " pass2; echo ''
        done
        encryptionpass=$pass1 
    fi

    read -r -p "Enter Drive Name: (E.g. sda or sdb, etc...) " drive 
    while [[ -z $drive || $drive =~ [0-9] ]]; do
        echo "Drive Name is invalid, please retry..."
        read -r -p "Enter Drive Name: (E.g. sda or sdb, etc...) " drive 
    done

    architecture=$(getconf LONG_BIT)
    if [ "$architecture" == "64" ]; then
        system="UEFI"
    else 
        system="BIOS"
    fi 

    read -r -p "Enter Swap Size(MB): " swapsize 
    while [ -z "$swapsize" ]; do
        echo "Swapsize is invalid, please retry..."
        read -r -p "Enter Swap Size(MB): " swapsize 
    done

    PS3='Choose Kernel: '
    options=("linux" "linux-lts" "linux-zen" "linux-hardened")
    select o in "${options[@]}"; do
        case $o in
            "linux") kernel=$o; break;;
            "linux-lts") kernel=$o; break;;
            "linux-zen") kernel=$o; break;;
            "linux-hardened") kernel=$o; break;;
            *) echo "Invalid option $REPLY";;
        esac
    done

    PS3='Choose Microcode: '
    options=("intel-ucode" "amd-ucode")
    select o in "${options[@]}"; do
        case $o in
            "intel-ucode") microcode=$o; break;;
            "amd-ucode") microcode=$o; break;;
            *) echo "Invalid option $REPLY";;
        esac
    done

    PS3='Choose Desktop Environment: '
    options=("gnome" "gnome-minimal" "xfce" "xfce-minimal" "kde" "kde-minimal" "NONE")
    select o in "${options[@]}"; do
        case $o in
            "gnome") desktopenvironment=$o; break;;
            "gnome-minimal") desktopenvironment=$o; break;;
            "xfce") desktopenvironment=$o; break;;
            "xfce-minimal") desktopenvironment=$o; break;;
            "kde") desktopenvironment=$o; break;;
            "kde-minimal") desktopenvironment=$o; break;;
            "NONE") desktopenvironment=""; break;;
            *) echo "Invalid option $REPLY";;
        esac
    done

    read -r -p "Enter Username: " username 
    while [[ -z $username || $username =~ [0-9] ]]; do
        read -r -p "Enter Username: " username 
    done
    username=$(echo "$username" | awk '{print tolower($0)}')

    read -r -s -p "Enter root password: " pass1; echo ''
    read -r -s -p "Re-enter root password: " pass2; echo ''
    while [[ "$pass1" != "$pass2" || -z "$pass1" ]]; do
        echo "Passwords do not match, please retry."
        read -r -s -p "Enter root password: " pass1; echo ''
        read -r -s -p "Re-enter root password: " pass2; echo ''
    done
    rootpass=$pass1 

    read -r -s -p "Enter user password: " pass1; echo ''
    read -r -s -p "Re-enter user password: " pass2; echo ''
    while [[ "$pass1" != "$pass2" || -z "$pass1" ]]; do
        echo "Passwords do not match, please retry."
        read -r -s -p "Enter user password: " pass1; echo ''
        read -r -s -p "Re-enter user password: " pass2; echo ''
    done
    userpass=$pass1 

    PS3='Choose Locale: '
    options=("en_GB" "en_US")
    select o in "${options[@]}"; do
        case $o in
            "en_GB") locale=$o; break;;
            "en_US") locale=$o; break;;
            *) echo "Invalid option $REPLY";;
        esac
    done

    PS3='Choose Region: '
    options=("Europe")
    select o in "${options[@]}"; do
        case $o in
            "Europe") region=$o; break;;
            *) echo "Invalid option $REPLY";;
        esac
    done

    PS3='Choose City: '
    options=("London")
    select o in "${options[@]}"; do
        case $o in
            "London") city=$o; break;;
            *) echo "Invalid option $REPLY";;
        esac
    done


    read -r -p "Enter Hostname: " hostname 
    while [[ -z $hostname || $hostname =~ [0-9] ]]; do
        echo "Hostname is invalid, please retry..."
        read -r -p "Enter Hostname: " hostname 
    done
    hostname=$(echo "$hostname" | awk '{print tolower($0)}')
    clear

    export ARCHER_DRIVE=${drive}
    export ARCHER_ENCRYPTED=${encrypted}
    export ARCHER_ENCRYPTED_PASSWORD=${encryptionpass}
    export ARCHER_SWAPSIZE=${swapsize}
    export ARCHER_SYSTEM=${system}
    export ARCHER_KERNEL=${kernel}
    export ARCHER_MICROCODE=${microcode}
    export ARCHER_DESKTOPENVIRONMENT=${desktopenvironment}
    export ARCHER_USER=${username}
    export ARCHER_USER_PASSWORD=${userpass}
    export ARCHER_ROOT_PASSWORD=${rootpass}
    export ARCHER_LOCALE=${locale}
    export ARCHER_REGION=${region}
    export ARCHER_CITY=${city}
    export ARCHER_HOSTNAME=${hostname}
    export ARCHER_HOST="127.0.0.1	localhost\n::1		    localhost\n127.0.1.1\n	$hostname.localdomain	$hostname\n"
}

function default_options() {
    export ARCHER_DRIVE=sda
    export ARCHER_ENCRYPTED=YES
    export ARCHER_ENCRYPTED_PASSWORD=1234
    export ARCHER_SWAPSIZE=256
    export ARCHER_SYSTEM=UEFI
    export ARCHER_KERNEL=linux
    export ARCHER_MICROCODE=intel-ucode
    export ARCHER_DESKTOPENVIRONMENT=gnome
    export ARCHER_USER=user
    export ARCHER_USER_PASSWORD=1234
    export ARCHER_ROOT_PASSWORD=1234
    export ARCHER_LOCALE=en_GB
    export ARCHER_REGION=Europe
    export ARCHER_CITY=London
    export ARCHER_HOSTNAME=arch-pc
    export ARCHER_HOST="127.0.0.1	localhost\n::1		    localhost\n127.0.1.1\n	arch-pc.localdomain	arch-pc\n"
}

function print_details(){
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
}

function check_details(){
    print_details
    echo -n "Are these details correct? [Y/n]: "; read arecorrect;
    if [[ $arecorrect == "Y" || $arecorrect == "y" ]]; then
        return 
    else
        main 
    fi 
}

function main(){
    #get_user_input
    #check_details

    default_options
}

# If no scripts directory exists then we terminate.
if [ ! -d "$(pwd)/scripts" ]; then 
    printf "No scripts folder present where the 'arch-installer.sh' script is located. Please reclone the repository using \n
    git clone https://github.com/james-d12/arch-installer.git."
    exit 1
fi

main

clear

print_home

# Run the 1st script which performs pre arch-chrooting tasks like formatting and mounting.
/bin/bash "$(pwd)/scripts/arch-install-01.sh"

# Run the 2nd script by chrooting into the mount point /mnt.
arch-chroot /mnt /bin/bash -c "bash /home/$ARCHER_USER/arch-install-scripts/scripts/arch-install-02.sh"

# Run the 3rd script as the newly created user, which installs the packages and desktop environment (if selected).
# arch-chroot /mnt /bin/bash -c "bash /home/$ARCHER_USER/arch-install-scripts/scripts/arch-install-03.sh"

# Run the 4th script as the newly created user, which installs the packages and desktop environment (if selected).
# arch-chroot /mnt /bin/bash -c "bash /home/$ARCHER_USER/arch-install-scripts/scripts/arch-install-04.sh"

# Cleanup by unmounting all drives.
# umount -R /mnt 

# Inform that the script has been completed.
# echo "Script has finished. Please shutdown, remove installation media and reboot."