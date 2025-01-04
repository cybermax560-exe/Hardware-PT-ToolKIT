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

# Update and upgrade system packages
echo -e "\e[34mUpdating package list...\e[0m"
if sudo apt-get update; then
    echo -e "\e[32mPackage list updated successfully.\e[0m"
else
    echo -e "\e[31mFailed to update package list. Please check your network connection.\e[0m"
    exit 1
fi

echo -e "\e[34mUpgrading packages...\e[0m"
if sudo apt-get upgrade -y; then
    echo -e "\e[32mPackages upgraded successfully.\e[0m"
else
    echo -e "\e[31mFailed to upgrade packages. Please check for errors.\e[0m"
    exit 1
fi

# Function to check if a package is installed and install it if not
check_install() {
    local package="$1"
    
    # Check if the package is installed
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
        echo -e "\e[32m$package is already installed and up-to-date.\e[0m"
    else
        echo -e "\e[31m$package is not installed or not up-to-date.\e[0m"
        echo -e "\e[34mInstalling $package...\e[0m"
        if sudo apt-get install -y "$package"; then
            echo -e "\e[32m$package installed successfully.\e[0m"
        else
            echo -e "\e[31mFailed to install $package. Please check for errors above.\e[0m"
        fi
    fi
}

# Specific function for checking and installing openjdk-17-jdk
check_openjdk() {
    local package="openjdk-17-jdk"
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
        echo -e "\e[32m$package is already installed and up-to-date.\e[0m"
    else
        echo -e "\e[31m$package is not installed or not up-to-date.\e[0m"
        echo -e "\e[34mInstalling $package...\e[0m"
        sudo apt-get install -y "$package"
        if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
            echo -e "\e[32m$package installed successfully.\e[0m"
        else
            echo -e "\e[31mFailed to install $package. Please check for errors above.\e[0m"
        fi
    fi
}

# Define the lists of tools to check and install
basic_tools=(git python3-pip curl wget openjdk-17-jdk p7zip-full zip)
main_tools=(flashrom minicom picocom sigrok pulseview binwalk wireshark nmap esptool screen bettercap ettercap-graphical john hashcat i2c-tools)

# Install basic tools
echo -e "\e[34mChecking and installing basic tools...\e[0m"
for tool in "${basic_tools[@]}"; do
    check_install "$tool"
done

# Install openjdk-17-jdk separately to avoid confusion
check_openjdk

# Install main tools
echo -e "\e[34mChecking and installing main tools...\e[0m"
for tool in "${main_tools[@]}"; do
    check_install "$tool"
done

# Additional setup and reminders
echo -e "\e[32mAll specified tools are installed and ready to use.\e[0m"

# Check and configure non-root access for Wireshark
if ! groups "$USER" | grep -q "\bwireshark\b"; then
    echo -e "\e[33mWireshark non-root access is not configured for user $USER.\e[0m"
    echo -e "\e[34mTo enable it, run:\e[0m"
    echo -e "\e[34msudo usermod -aG wireshark $USER\e[0m"
    echo -e "\e[34mThen log out and back in for the changes to take effect.\e[0m"
fi

# Final message
echo -e "\e[32mSetup completed successfully! Happy Hacking!\e[0m"
