#!/usr/bin/env bash

# Arch Installer By james-d12
# GitHub Repository: https://github.com/james-d12/arch-installer


print_home(){
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

get_user_input(){
    clear

    print_home
    PS3='Encrypt Drive? '
    options=("YES" "NO")
    select o  in "${options[@]}"; do
        case $o in
            "YES" | "NO") encrypted=$o; break;;
            *);;
        esac
    done

    if [ "$encrypted" == "YES" ]; then 
        read -s -p "Enter encryption password: " pass1; echo ''
        read -s -p "Re-enter encryption password: " pass2; echo ''
        while [ $pass1 != $pass2 ]; do
            echo "Passwords do not match, please retry."
            read -s -p "Enter encryption password: " pass1; echo ''
            read -s -p "Re-enter encryption password: " pass2; echo ''
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
    while [ -z $swapsize ]; do
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

    echo "Enter user password: "; read -s pass1 
    echo "Re-enter user password: "; read -s pass2 
    while [ $pass1 != $pass2 ]; do
        echo "Passwords do not match, please retry."
        echo "Enter user password: "; read -s pass1 
        echo "Re-enter user password: "; read -s pass2
    done
    userpass=$pass1 

    echo "Enter root password: "; read -s pass1;
    echo "Re-enter root password: "; read -s pass2; 
    while [ $pass1 != $pass2 ]; do
        echo "Passwords do not match, please retry."
        echo "Enter root password: "; read -s pass1 
        echo "Re-enter root password: "; read -s pass2
    done
    rootpass=$pass1 

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
        read -r -p "Enter Drive: " hostname 
    done
    hostname=$(echo "$hostname" | awk '{print tolower($0)}')
    clear
}

output_to_config_file(){
cat <<EOF > $(pwd)/arch-config.sh
#!/usr/bin/env bash
drive="${drive}"
encrypted="${encrypted}"
encryptionpass="${encryptionpass}"
swapsize="${swapsize}"
system="${system}" 
kernel="${kernel}"
microcode="${microcode}"
desktopenvironment="${desktopenvironment}"
user="${username}"
userpass="${userpass}"
rootpass="${rootpass}"
locale="${locale}"
region="${region}"
city="${city}"
hostname="${hostname}"
host="
127.0.0.1	localhost
::1		    localhost
127.0.1.1	$hostname.localdomain	$hostname"
EOF
}

print_details(){
echo "
drive="${drive}"
encrypted="${encrypted}"
encryptionpass="${encryptionpass}"
swapsize="${swapsize}"
system="${system}" 
kernel="${kernel}"
microcode="${microcode}"
desktopenvironment="${desktopenvironment}"
user="${username}"
userpass="${userpass}"
rootpass="${rootpass}"
locale="${locale}"
region="${region}"
city="${city}"
hostname="${hostname}""
}

check_details(){
    print_details
    echo -n "Are these details correct? [Y/n]: "; read arecorrect;
    if [[ $arecorrect == "Y" || $arecorrect == "y" ]]; then
        output_to_config_file
        return 
    else
        main 
    fi 
}

main(){
    get_user_input
    check_details
}

main 