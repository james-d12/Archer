#!/usr/bin/env bash

#**************************** GET IF ENCRYPT ************************#
PS3='Encrypt Drive? '
options=("YES" "NO")
select o  in "${options[@]}"; do
    case $o in
        "YES") encrypted=$o; break;;
        "NO") encrypted=$o; break;;
        *) echo "Invalid option $REPLY";;
    esac
done

#**************************** GET SWAP SIZE (ENCRYPTED) *************#
if [ "$encrypted" == "YES" ]; then
    while [ -z $encryptedswapsize ]; do
        echo -n "Enter Encrypted Swap Size(MB): "; 
        read encryptedswapsize
    done
fi

#**************************** GET DRIVE NAME ************************#
while [ -z $drive ]; do
    echo -n "Enter Drive Name: "; 
    read drive
done

#**************************** GET SYSTEM TYPE ************************#
PS3='Choose System: '
options=("BIOS" "UEFI")
select o  in "${options[@]}"; do
    case $o in
        "BIOS") system=$o; break;;
        "UEFI") system=$o; break;;
        *) echo "Invalid option $REPLY";;
    esac
done

#**************************** GET KERNEL TYPE ************************#
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

#**************************** GET MICROCODE ************************#
PS3='Choose Microcode: '
options=("intel-ucode" "amd-ucode")
select o in "${options[@]}"; do
    case $o in
        "intel-ucode") microcode=$o; break;;
        "amd-ucode") microcode=$o; break;;
        *) echo "Invalid option $REPLY";;
    esac
done

#**************************** GET DESKTOP ************************#
PS3='Choose Desktop Environment: '
options=(
    "gnome" "gnome-minimal" 
    "xfce" "xfce-minimal"
    "custom" "NONE"
)
select o in "${options[@]}"; do
    case $o in
        "gnome") desktopenvironment=$o; break;;
        "gnome-minimal") desktopenvironment=$o; break;;
        "xfce") desktopenvironment=$o; break;;
        "xfce-minimal") desktopenvironment=$o; break;;
        "custom") desktopenvironment=$o; break;;
        "NONE") desktopenvironment=""; break;;
        *) echo "Invalid option $REPLY";;
    esac
done

#**************************** GET USERNAME ************************#
while [ -z $username ]; do
    echo -n "Enter Username: "; 
    read username
done
username=$(echo "$username" | awk '{print tolower($0)}')

#**************************** GET LOCALE ************************#
PS3='Choose Locale: '
options=("en_GB" "en_US")
select o in "${options[@]}"; do
    case $o in
        "en_GB") locale=$o; break;;
        "en_US") locale=$o; break;;
        *) echo "Invalid option $REPLY";;
    esac
done

#**************************** GET REGION ************************#
PS3='Choose Region: '
options=("Europe")
select o in "${options[@]}"; do
    case $o in
        "Europe") region=$o; break;;
        *) echo "Invalid option $REPLY";;
    esac
done

#**************************** GET CITY ************************#
PS3='Choose City: '
options=("London")
select o in "${options[@]}"; do
    case $o in
        "London") city=$o; break;;
        *) echo "Invalid option $REPLY";;
    esac
done

#**************************** GET HOSTNAME ************************#
while [ -z $hostname ]; do
    echo -n "Enter Hostname: "; 
    read hostname
done
hostname=$(echo "$hostname" | awk '{print tolower($0)}')
host="\n127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$hostname.localdomain   $hostname"

#**************************** OUTPUT TO CONFIG FILE ************************#
rm -rf arch-config.sh
touch arch-config.sh

echo "#!/usr/bin/env bash
MSGCOLOUR='\033[0;33m'
PROMPTCOLOUR='\033[0;32m'
NC='\033[0m'" >> arch-config.sh

echo -e "
drive="'"'${drive}'"'"
encrypted="'"'${encrypted}'"'"
encryptedswapsize="'"'${encryptedswapsize}'"'"
system="'"'${system}'"'" 
kernel="'"'${kernel}'"'"
microcode="'"'${microcode}'"'"
desktopenvironment="'"'${desktopenvironment}'"'"
user="'"'${username}'"'"
locale="'"'${locale}'"'"
region="'"'${region}'"'"
city="'"'${city}'"'"
hostname="'"'${hostname}'"'"
host="'"'${host}'"'"
" >> arch-config.sh 

bash arch-install-01.sh 