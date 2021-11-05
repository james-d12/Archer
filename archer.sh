#!/usr/bin/env bash

copy_files(){
    mkdir -p /mnt/arch-install-scripts/
    cp -r * /mnt/arch-install-scripts/
}

bash $(pwd)/scripts/arch-install-00.sh 
bash arch-install-01.sh 
copy_files
arch-chroot /mnt /bin/bash -c "bash arch-install-scripts/arch-install-02.sh"
umount -R /mnt && echo "Script has finished, please shutdown, remove the USB/Installation Media and then reboot."