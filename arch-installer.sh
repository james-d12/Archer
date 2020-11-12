#!/usr/bin/bash 

# Arch Installer By james-d12
# GitHub Repository: https://github.com/james-d12/arch-installer

# If no scripts directory exists then we terminate.
if [ ! -d "$(pwd)/scripts" ]; then 
    printf "No scripts folder present where the 'arch-installer.sh' script is located. Please reclone the repository using \n
    git clone https://github.com/james-d12/arch-installer.git."
    exit 1
fi

# Run the first script - prompting user for configuration settings.
/bin/bash "$(pwd)/scripts/arch-install-00.sh"
# Include the newly created 'arch-config.sh' file in this script.
. "$(pwd)/scripts/arch-config.sh"
# Run the 2nd script which performs pre arch-chrooting tasks like formatting and mounting.
/bin/bash "$(pwd)/scripts/arch-install-01.sh"
# Run the 3rd script by chrooting into the mount point /mnt.
arch-chroot /mnt /bin/bash -c "bash $(pwd)/scripts/arch-install-02.sh"
# Run the 4th script as the newly created user, which installs the packages and desktop environment (if selected).
su -c "bash /home/""$user""/arch-install-scripts/arch-install-03.sh" - "$user" 

# Cleanup by unmounting all drives.
umount -R /mnt 

# Inform that the script has been completed.
echo "Script has finished. Please shutdown, remove installation media and reboot."