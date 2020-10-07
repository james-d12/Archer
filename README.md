# Overview
The programs that the third script will install are located in the resources/programs.csv file. To add new programs specify 
the installer type, then the package name, then a description of the package.
    - PACMAN    - Uses pacman to install package.
    - AUR       - Uses an AUR helper (yay) to install package.
    - GIT       - Uses git to clone and uses makepkg to install package.
    - VSCODE    - Uses vscode cli to install extensions.
    - PIP       - Uses python-pip to install python libraries.
So for example to add chromium package to be installed add 
PACMAN, chromium, Open source google chrome. 


# Steps
1. Boot into a live USB for arch linux.
2. Run 'pacman -Syy && pacman -S git' on the arch linux live iso.
3. Run 'git clone https://github.com/james-d12/arch-installer.git'
4. Change to the 'arch-installer' directory 'cd arch-installer'.
5. Run the first script 'bash arch-install-00.sh'
6. Answer any prompts for the first script, which asks about the configuration such as 
the root password, what the system type is and what desktop environment it will, or will not, install.
7. Tea break, then return and hopefully you will be greeted with either a decryption screen, or a user login screen
depending on if you chose to encrypt the disk or not.
8. Run the 3rd script located in the 'arch-install-scripts' as the newly created user located in the folder in the users's home directory.
9. Another tea break. You should be greeted with the display manager for your chosen desktop environment asking for a login.
10. Login and you are done. 

Note: The 4th script configures network and security settings it is optional but recommended.