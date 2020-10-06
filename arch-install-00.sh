#!/usr/bin/bash 

get_user_input(){
    clear
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
        echo "Enter encryption password: "; read -s pass1;
        echo "Re-enter encryption password: "; read -s pass2; 
        while [ $pass1 != $pass2 ]; do
            echo "Passwords do not match, please retry."
            echo "Enter encryption password: "; read -s pass1;
            echo "Re-enter encryption password: "; read -s pass2; 
        done
        encryptionpass=$pass1 
    fi

    while [ -z $drive ]; do
        echo -n "Enter Drive Name: "; 
        read drive
    done

    PS3='Choose System: '
    options=("BIOS" "UEFI")
    select o  in "${options[@]}"; do
        case $o in
            "BIOS") system=$o; break;;
            "UEFI") system=$o; break;;
            *) echo "Invalid option $REPLY";;
        esac
    done

    if [ "$system" == "UEFI" ]; then 
        while [ -z $swapsize ]; do
            echo -n "Enter Swap Size(MB): "; 
            read swapsize
        done 
    fi 

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

    while [ -z $username ]; do
        echo -n "Enter Username: "; 
        read username
    done
    username=$(echo "$username" | awk '{print tolower($0)}')

    echo "Enter root password: "; read -s pass1;
    echo "Re-enter root password: "; read -s pass2; 
    while [ $pass1 != $pass2 ]; do
        echo "Passwords do not match, please retry."
        echo "Enter root password: "; read -s pass1 
        echo "Re-enter root password: "; read -s pass2
    done
    rootpass=$pass1 

    echo "Enter user password: "; read -s pass1 
    echo "Re-enter user password: "; read -s pass2 
    while [ $pass1 != $pass2 ]; do
        echo "Passwords do not match, please retry."
        echo "Enter user password: "; read -s pass1 
        echo "Re-enter user password: "; read -s pass2
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

    while [ -z $hostname ]; do
        echo -n "Enter Hostname: "; 
        read hostname
    done
    hostname=$(echo "$hostname" | awk '{print tolower($0)}')
    clear
}

output_to_config_file(){
cat <<EOF > arch-config.sh
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
 
get_user_input
output_to_config_file
bash arch-install-01.sh 