#!/bin/bash

# Function to print the banner
print_banner() {
    echo -e "\e[32m#######################################\e[0m" 
    echo -e "\e[32m#                                     #\e[0m"
    echo -e "\e[32m#         Hardware-PT Toolkit         #\e[0m"
    echo -e "\e[32m#         Created by Cybermax         #\e[0m"
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
    if dpkg -l | grep -q "$1"; then
        echo "$1 is already installed." 
    else
        echo "$1 is not installed."
        echo "Installing $1..."
        sudo apt-get install -y "$1"
    fi
}

# Install basic tools if not installed
basic_tools=(git pip curl wget openjdk-17-jdk p7zip-full zip lolcat)

echo "Checking and installing basic tools..." 
for tool in "${basic_tools[@]}"; do
    check_install "$tool"
done

# Install main tools
main_tools=(flashrom minicom picocom sigrok pulseview binwalk wireshark nmap esptool)

echo "Checking and installing main tools..." 
for tool in "${main_tools[@]}"; do
    check_install "$tool"
done

# Additional steps after installation
echo "All specified tools are installed and ready to use." 

# Reminder: Configure non-root access to Wireshark if necessary
if [ "$USER" != "root" ]; then
    echo "If using Wireshark as a non-root user, you may need to configure permissions:"
    echo "sudo usermod -aG wireshark $USER"
fi

echo "Happy Hacking and fuck the Hardware." | lolcat
