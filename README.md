# Disclaimer
This script should not be used by someone not familiar with the arch installation process at the current time, it should not be seen as a replacement to learning the arch installation script. Additionally, if possible the script should be tested in a virtual machine/environment with your config before hand to ensure it will run correctly.

# Overview
This is a simple collection of scripts that aims to automate the arch installation process to make it quicker and faster, but still allows for full customisation of the install. Packages are installed from the resources/programs.csv file and can be fully edited to fit your needs.

# Programs
The programs that the third script will install are located in the resources/programs.csv file. To add new programs specify 
the installer type, then the package name, then a description of the package, ensure each value is separated by a comma.
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
7. Tea break, then return to a message saying the script has finished and that you should shutdown, remove the installation media then power on the machine.
8. If you encrypted your installation, you will have to decrypt the drive, then you should be greeted with a terminal login screen. Login to your user 
and change directory to the 'arch-install'scripts' cd arch-install-scripts
9. If you haven't edited the resources/programs.csv file, do so at this point.
10. Run the 3rd script located in the 'arch-install-scripts' as the newly created user located in the folder in the users's home directory.
11. Another tea break. You should be greeted with the display manager for your chosen desktop environment asking for a login.
12. Login and you are done. 

Note: The 4th script configures network and security settings it is optional but recommended.
