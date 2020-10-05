#!/usr/bin/env bash

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
        while [ -z $swapsize ]; do
            echo -n "Enter Encrypted Swap Size(MB): "; 
            read swapsize
        done
    else 
        while [ -z $swapsize ]; do
            echo -n "Enter Swap Size(MB): "; 
            read swapsize
        done
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

    PS3='Choose Kernel: '
    options=("linux" "linux-lts" "linux-hardened")
    select o in "${options[@]}"; do
        case $o in
            "linux") kernel=$o; break;;
            "linux-lts") kernel=$o; break;;
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
    options=(
        "gnome" "gnome-minimal" 
        "xfce" "xfce-minimal"
        "i3" "custom" "NONE"
    )
    select o in "${options[@]}"; do
        case $o in
            "gnome") desktopenvironment=$o; break;;
            "gnome-minimal") desktopenvironment=$o; break;;
            "xfce") desktopenvironment=$o; break;;
            "xfce-minimal") desktopenvironment=$o; break;;
            "i3") desktopenvironment=$o; break;;
            "custom") desktopenvironment=$o; break;;
            "NONE") desktopenvironment=""; break;;
            *) echo "Invalid option $REPLY";;
        esac
    done

    while [ -z $username ]; do
        echo -n "Enter Username: "; 
        read username
    done
    username=$(echo "$username" | awk '{print tolower($0)}')

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
    host="\n127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$hostname.localdomain   $hostname"
}

output_to_config_file(){
    rm -rf arch-config.sh
    touch arch-config.sh

    echo "#!/usr/bin/env bash
    MSGCOLOUR='\033[0;33m'
    PROMPTCOLOUR='\033[0;32m'
    NC='\033[0m'" >> arch-config.sh

    echo -e "
    drive="'"'${drive}'"'"
    encrypted="'"'${encrypted}'"'"
    swapsize="'"'${swapsize}'"'"
    system="'"'${system}'"'" 
    kernel="'"'${kernel}'"'"
    microcode="'"'${microcode}'"'"
    desktopenvironment="'"'${desktopenvironment}'"'"
    user="'"'${username}'"'"
    locale="'"'${locale}'"'"
    region="'"'${region}'"'"
    city="'"'${city}'"'"
    hostname="'"'${hostname}'"'"
    host="'"'${host}'"'"" >> arch-config.sh 
}
 
get_user_input
output_to_config_file
bash arch-install-01.sh 