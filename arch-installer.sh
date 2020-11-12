#!/usr/bin/bash 

# Arch Installer By james-d12
# GitHub Repository: https://github.com/james-d12/arch-installer


bash "$(pwd)/scripts/arch-install-00.sh"
. "$(pwd)/scripts/arch-config.sh"
bash "$(pwd)/scripts/arch-install-01.sh"
arch-chroot /mnt /bin/bash -c "bash $(pwd)/scripts/arch-install-02.sh"
su -c "bash /home/"$user"/arch-install-scripts/arch-install-03.sh" - "$user" 
umount -R /mnt 
echo -ne "Script has finished."