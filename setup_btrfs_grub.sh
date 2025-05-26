#!/bin/sh -e

# This script automates the installation and root and home snapshot configuration of Snapper and installs Grub-Btrfs on Debian systems.

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
GREEN='\033[32m'

# Check if script runs as root
checkRoot() {
if [ "$EUID" -ne 0 ]; then
  printf "%b\n" "${RED}Please run with root privileges.${RC}"
  exit
fi
}

# Check command
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Package Manager
checkPackageManager() {
    PACKAGEMANAGER=$1
    for pgm in ${PACKAGEMANAGER}; do
        if command_exists "${pgm}"; then
            PACKAGER=${pgm}
            printf "%b\n" "${CYAN}Using ${pgm} as package manager${RC}"
            break
        fi
    done

    if [ -z "$PACKAGER" ]; then
        printf "%b\n" "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi
}

# Check File System
checkFs() {
    fs_type=$(findmnt -n -o FSTYPE /)
    if [ "$fs_type" != "btrfs" ]; then
      printf "%b\n" "${RED}This operation can only be performed on a Btrfs filesystem.${RC}"
      exit 1
    fi
    printf "%b\n" "${GREEN}Btrfs filesystem detected. Continuing with the operation...${RC}"
}

# Install Btrfs-Assistant/snapper and dependencies
installBtrfsStack() {
    if ! command -v btrfs-assistant &> /dev/null; then
        printf "%b\n" "${YELLOW}==========================================${RC}"
        printf "%b\n" "${YELLOW}Installing Btrfs Assistant from .deb...${RC}"
        printf "%b\n" "${YELLOW}==========================================${RC}"
        
        TMP_DEB="/tmp/btrfs-assistant.deb"
        wget -O "$TMP_DEB" "http://archive.ubuntu.com/ubuntu/pool/universe/b/btrfs-assistant/btrfs-assistant_2.1.1-1_amd64.deb"
        
        if [ -f "$TMP_DEB" ]; then
            sudo apt install -y "$TMP_DEB"
            rm -f "$TMP_DEB"
        else
            printf "%b\n" "${RED}Failed to download the .deb package.${RC}"
            exit 1
        fi
    else
        printf "%b\n" "${GREEN}Btrfs Assistant is already installed.${RC}"
    fi
}

# Create first snapper config for root and home and create new manual snapshots
configureSnapper() {
    printf "%b\n" "${YELLOW}===========================================================================${RC}"
    printf "%b\n" "${YELLOW}Creating snapper root(/) and /home config and taking the first snapshots...${RC}"
    printf "%b\n" "${YELLOW}===========================================================================${RC}"
    sudo snapper -c home create-config /home && sudo snapper -c home create --description "First home Snapshot"
    sudo snapper -c root create-config / && sudo snapper -c root create --description "First root Snapshot"
    printf "%b\n" "${YELLOW}Updating timeline settings...${RC}"
    # Modifyling default timeline root config
    sudo sed -i'' '
        s/^TIMELINE_LIMIT_HOURLY="[^"]*"/TIMELINE_LIMIT_HOURLY="1"/;
        s/^TIMELINE_LIMIT_DAILY="[^"]*"/TIMELINE_LIMIT_DAILY="2"/;
        s/^TIMELINE_LIMIT_WEEKLY="[^"]*"/TIMELINE_LIMIT_WEEKLY="1"/;
        s/^TIMELINE_LIMIT_MONTHLY="[^"]*"/TIMELINE_LIMIT_MONTHLY="0"/;
        s/^TIMELINE_LIMIT_YEARLY="[^"]*"/TIMELINE_LIMIT_YEARLY="0"/
    ' /etc/snapper/configs/root
    # Modifyling default timeline for home config
    sudo sed -i'' '
        s/^TIMELINE_LIMIT_HOURLY="[^"]*"/TIMELINE_LIMIT_HOURLY="2"/;
        s/^TIMELINE_LIMIT_DAILY="[^"]*"/TIMELINE_LIMIT_DAILY="1"/;
        s/^TIMELINE_LIMIT_WEEKLY="[^"]*"/TIMELINE_LIMIT_WEEKLY="0"/;
        s/^TIMELINE_LIMIT_MONTHLY="[^"]*"/TIMELINE_LIMIT_MONTHLY="1"/;
        s/^TIMELINE_LIMIT_YEARLY="[^"]*"/TIMELINE_LIMIT_YEARLY="0"/
    ' /etc/snapper/configs/home
    printf "%b\n" "${GREEN}Snapper configs and first snapshots created.${RC}"
}

# Starting services
serviceStartEnable() {
    printf "%b\n" "${YELLOW}==================================================================================${RC}"
    printf "%b\n" "${YELLOW}Starting and enabling snapper-timeline.timer and snapper-cleanup.timer services...${RC}"
    printf "%b\n" "${YELLOW}==================================================================================${RC}"
    sudo systemctl enable --now snapper-timeline.timer
    sudo systemctl enable --now snapper-cleanup.timer
    printf "%b\n" "${GREEN}Snapper services started and enabled.${RC}"
}

# Ask user if they want to install grub-btrfs
askInstallGrubBtrfs() {
    printf "%b\n" "${YELLOW}=====================================${RC}"
    printf "%b\n" "${YELLOW}(optional) grub-btrfs installation...${RC}"
    printf "%b\n" "${YELLOW}=====================================${RC}"
    printf "%b\n" "${YELLOW}You can skip installing grub-btrfs and use only Btrfs Assistant GUI or snapper CLI.${RC}"

    while true; do
        printf "%b" "${YELLOW}Do you want to install grub-btrfs? Press (y) for yes, (n) for no: ${RC}"
        read -r response
        case "$response" in
            [yY]*)
                installGrubBtrfs
                break
                ;;
            [nN]*)
                printf "%b\n" "${GREEN}Skipping grub-btrfs installation.${RC}"
                break
                ;;
            *)
                printf "%b\n" "${RED}Invalid input. Please enter 'y' for yes, 'n' for no.${RC}"
                ;;
        esac
    done
}

# Install grub-btrfs
installGrubBtrfs() {
    printf "%b\n" "${YELLOW}Downloading grub-btrfs and installing dependencies...${RC}"
    sudo apt install -y make git
    
    printf "%b\n" "${YELLOW}Cloning grub-btrfs repository...${RC}"
    git clone https://github.com/Antynea/grub-btrfs.git
    
    printf "%b\n" "${YELLOW}Installing grub-btrfs...${RC}"
    cd grub-btrfs
    sudo make install
    
    printf "%b\n" "${YELLOW}Updating grub configuration and enabling grub-btrfsd service...${RC}"
    sudo systemctl enable --now grub-btrfsd.service
    
    printf "%b\n" "${GREEN}Grub-btrfs installed and service enabled.${RC}"
    printf "%b\n" "${CYAN}Notice: To perform a system recovery via grub-btrfs, perform a restore operation with Btrfs Assistant GUI after booting into the snapshot.${RC}"
    
}


# Post install information
someNotices() {
    printf "%b\n" "${YELLOW}================================NOTICES================================${RC}"
    printf "%b\n" "${YELLOW}Notice: You can manage snapshots from GUI with Btrfs Assistant or CLI with snapper.${RC}"
    printf "%b\n" "${YELLOW}Notice: You may change (Hourly, daily, weekly, monthly, yearly) timeline settings with Btrfs Assistant GUI.${RC}"
    printf "%b\n" "${RED}Notice: If you used the default Fedora disk partitioning during OS installation, the /boot configured as an separate EXT4 partition. Therefore, it cannot be included in root snapshots. Backup separately...${RC}"
    printf "%b\n" "${YELLOW}================================NOTICES================================${RC}"
    printf "%b\n" "${GREEN}Setup process completed.${RC}"
}

checkRoot
checkPackageManager 'apt'
checkFs
installBtrfsStack
configureSnapper
serviceStartEnable
askInstallGrubBtrfs
someNotices
