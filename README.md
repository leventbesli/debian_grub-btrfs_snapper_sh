# Btrfs Assistant & Grub-Btrfs Setup for Debian Linux

This bash script automates the installation and configuration of Btrfs Assistant and Grub-Btrfs on Debian based systems. It enables Btrfs snapshots to be displayed in the Grub boot menu and sets up automatic snapshot creation and Grub configuration updates.

# Features
- Installs Btrfs-Assistan/Snapper and takes the first root snapshot.
- Downloads, configures, and installs Grub-Btrfs to display snapshots in the GRUB menu.
- Configures automatic GRUB configuration updates after each snapshot.

# Prerequisites
- Debian-based OS with btrfs file sytem.
- Root privileges.
  
# Installation
- Download and make the script executable:

```
chmod +x setup_btrfs_grub.sh
```

- Run the script with root privileges:

```
sudo ./setup_btrfs_grub.sh
```

After completing the process, you can manage snapshots from the GUI with Btrfs Assistant.
![{BC68E75D-972E-43BB-8A90-FB23AA43846B}](https://github.com/user-attachments/assets/7db1c2e2-04d6-4a85-a66f-bffbb5d11b01)

And you can see the snapshots taken on the GRUB screen.
![grub1](https://github.com/user-attachments/assets/5af97ca0-4c73-45cf-b4df-daf7355cf3e0)![grub2](https://github.com/user-attachments/assets/229fd63c-91c2-49dc-916e-97d2d6ed3c82)

# NOTICES
- You can manage snapshots from GUI with Btrfs Assistant or CLI with snapper.
- You may change (Hourly, daily, weekly, monthly, yearly) timeline settings with Btrfs Assistant GUI.
- If your /boot configured as an separate EXT4 partition it cannot be included in root snapshots. Backup separately.

# Resources
- https://github.com/leventbesli/fedora_grub-btrfs_snapper_sh 



