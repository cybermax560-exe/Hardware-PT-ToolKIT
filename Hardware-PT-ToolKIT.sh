#!/bin/bash

# Function to print the banner
print_banner() {
    echo -e "\e[32m#######################################\e[0m" 
    echo -e "\e[32m#                                     #\e[0m"
    echo -e "\e[32m#         Hardware-PT Toolkit         #\e[0m"
    echo -e "\e[32m#       Created by Cybermax560        #\e[0m"
    echo -e "\e[32m#                                     #\e[0m"
    echo -e "\e[32m#######################################\e[0m"
}

# Print the banner
print_banner

# Update package list
echo "Updating package list..."  
sudo apt-get update
echo "Package list updated."     

# Upgrade packages
echo "Upgrading packages..."     
sudo apt-get upgrade -y
echo "Packages upgraded."  

# Function to check if a package is installed
check_install() {
    if dpkg -l | grep -q "^ii  $1 "; then
        echo "$1 is already installed." 
    else
        echo -e "\e[31m $1 is not installed. \e[0m"
        echo -e "\e[32m Installing $1...  \e[0m" 
        sudo apt-get install -y "$1"

        # Check if the installation was successful
        if dpkg -l | grep -q "^ii  $1 "; then
            echo -e "\e[32m $1 installed successfully.  \e[0m"
        else
            echo "Failed to install $1. Please check for errors above."
        fi
    fi
}

# Install basic tools if not installed
basic_tools=(git python3-pip curl wget openjdk-17-jdk p7zip-full zip )

echo -e "\e[32m Checking and installing basic tools... \e[0m" 
for tool in "${basic_tools[@]}"; do
    check_install "$tool"
done

# Install main tools
main_tools=(flashrom minicom picocom sigrok pulseview binwalk wireshark nmap esptool screen bettercap ettercap-graphical john hashcat)

echo -e "\e[32m Checking and installing main tools... \e[0m"
for tool in "${main_tools[@]}"; do
    check_install "$tool"
done

# Additional steps after installation
echo -e "\e[32m All specified tools are installed and ready to use.  \e[0m"
# Reminder: Configure non-root access to Wireshark if necessary
if [ "$USER" != "root" ]; then
    echo -e "\e[32m If using Wireshark as a non-root user, you may need to configure permissions: \e[0m"
    echo -e "\e[32m sudo usermod -aG wireshark $USER  \e[0m"
fi

echo -e "\e[31m Happy Hacking And Fuck The Hardware!  \e[0m"
