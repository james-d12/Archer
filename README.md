# Disclaimer
This script should not be used by someone not familiar with the arch installation process at the current time, it should not be seen as a replacement to learning the arch installation process. Additionally, if possible the script should be tested in a virtual machine/environment with your config before hand to ensure it will run correctly.

# Overview
This is a simple collection of scripts that aims to automate the arch installation process to make it quicker and faster, but still allows for full customisation of the install. Packages are installed from the resources/programs.csv file and can be fully edited to fit your needs.

# Steps
1. Boot into a live USB for arch linux.
2. Run 'pacman -Syy && pacman -S git' on the arch linux live iso.
3. Run 'git clone https://github.com/james-d12/arch-installer.git'
4. Change to the 'arch-installer' directory 'cd arch-installer'.
5. Run the first script 'bash arch-install-00.sh'
6. Answer any prompts for the first script, which asks about the configuration such as 
the root password, what the system type is and what desktop environment it will, or will not, install.
7. Tea break, then return to a message saying the script has finished and that you should shutdown (with the command 'shutdown -now'), remove the installation media then power on the machine.
8. If you encrypted your installation, you will have to decrypt the drive, then you should be greeted with a terminal login screen. Login to your user 
and change directory to the 'arch-install'scripts' cd arch-install-scripts
9. If you haven't edited the resources/programs.csv file, do so at this point.
10. Run the 3rd script located in the 'arch-install-scripts' as the newly created user located in the folder in the users's home directory.
11. Another tea break. You should be greeted with the display manager for your chosen desktop environment asking for a login.
12. Login and you are done. 

Note: The 4th script configures network and security settings it is optional but recommended.

# Customisation

## Desktop Environment
This script aims to be very customisable and with that comes with 3 desktop environments pre set to choose from (gnome, kde, xfce) each with a 'minimal' version including a reduced number of applications. You can also choose 'None' and therefore not install any of the desktop environments if you would like to install one not included within the script. 

## Packages
Packages are read from the 'resources/programs.csv' file, and each package contains 3 pieces of data:
 - Installer: What installer is used to install the package (E.g. pacman, git, etc...)
 - Package Name: The package's name to install (E.g. firefox)
 - Description: A short description of the package.
They are all separated by a comma, and example for adding firefox to the file would be as follows:
**PACMAN, firefox, A web browser**
It is important that you do not forget commas otherwise it will cause the script to break when reading the file.

## List of Available Installers
The installation script (arch-install-03.sh) supports the following installers:
    - PACMAN    - Uses pacman to install package.
    - AUR       - Uses an AUR helper (yay) to install package.
    - GIT       - Uses git to clone and uses makepkg to install package.
    - VSCODE    - Uses vscode cli to install extensions.
    - PIP       - Uses python-pip to install python libraries.

<<<<<<< HEAD
## Systemd Services
By default the scripts support a handful of services out of the box including automatically enabling services for the window managers for each desktop environment and enabling the firewall. However if you add a program that needs its service to be enabled, you may have to do so manually. 
Here is the list of currently automatically enabled systemd services:
    - Uncomplicated Firewall
    - Network Manager
    - Apparmor
    - Firejail
    - Cronie
    - Gnome Display Manager (gdm)
    - SDDM
    - Light Display Manager (lightdm)
    
=======
# Steps
1. Boot into a live USB for arch linux.
2. Run 'pacman -Syy && pacman -S git' on the arch linux live iso.
3. Run 'git clone https://github.com/james-d12/arch-installer.git'
4. Change to the 'arch-installer' directory 'cd arch-installer'.
5. Run the first script 'bash arch-install-00.sh'
6. Answer any prompts for the first script, which asks about the configuration such as 
the root password, what the system type is and what desktop environment it will, or will not, install.
7. Tea break, then return to a message saying the script has finished and that you should shutdown (with the command 'shutdown -now'), remove the installation media then power on the machine.
8. If you encrypted your installation, you will have to decrypt the drive, then you should be greeted with a terminal login screen. Login to your user 
and change directory to the 'arch-install'scripts' cd arch-install-scripts
9. If you haven't edited the resources/programs.csv file, do so at this point.
10. Run the 3rd script located in the 'arch-install-scripts' as the newly created user located in the folder in the users's home directory.
11. Another tea break. You should be greeted with the display manager for your chosen desktop environment asking for a login.
12. Login and you are done. 

Note: The 4th script configures network and security settings it is optional but recommended.
>>>>>>> 0b70d6f7ccdd9ddeea5300fe5d5868cbec8b5957
