#!/bin/bash

# Automated-Arch-Install-w/Bash

# Update mirrorlist
reflector --country India --age 48 --fastest 5 --latest 10 --sort rate --save /etc/pacman.d/mirrorlist --verbose

# Disk partition
sgdisk -Z /dev/vda
sgdisk -n 1::+1G -c 1:"EFI BOOT Partition" -t 1:ef00 /dev/vda
sgdisk -n 2:: -c 2:"Linux Partition" -t 2:8300 /dev/vda
sgdisk -p /dev/vda

# Format partitions
mkfs.ext4 /dev/vda2
mkfs.fat -F 32 /dev/vda1

# Mount filesystems
mount /dev/vda2 /mnt
mount --mkdir /dev/vda1 /mnt/boot

# Install essential packages
pacstrap -K /mnt base base-devel linux linux-firmware amd-ucode neovim man-db tealdeer grub efibootmgr

# System configuration
genfstab -U /mnt >> /mnt/etc/fstab

# Timezone
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
arch-chroot /mnt hwclock --systohc

# Localization
arch-chroot /mnt sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
arch-chroot /mnt locale-gen
touch /mnt/etc/locale.conf
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

# Hostname
touch /mnt/etc/hostname
read -p "hostname: " hostname
echo $hostname > /mnt/etc/hostname

# Grub-install
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Network configuration
touch /mnt/etc/systemd/network/10-wired.network
echo -e "[Match]\nName=en*\n\n[Link]\nRequiredforOnline=routable\n\n[Network]\nDHCP=yes" >> /mnt/etc/systemd/network/10-wired.network
arch-chroot /mnt ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# DNS configuration
mkdir /etc/systemd/resolved.conf.d
touch /etc/systemd/resolved.conf.d/dns_servers.conf
echo -e "[Resolve]\nDNS=8.8.8.8 ::1\nDomains=~." >> /etc/systemd/resolved.conf.d/dns_servers.conf
systemctl enable --now systemd-networkd
systemctl enable --now systemd-resolved

# Useradd
read -p "username: " username
read -sep "password: " password
useradd -m $username
echo $password | passwd $username --stdin
usermod -aG wheel $username
arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Enable multilib
arch-chroot /mnt sed -i 's/#\[multilib\]/\[multilib\]/' /etc/pacman.conf
arch-chroot /mnt sed -i 's\#Include = /etc/pacman.d/mirrorlist\Include = /etc/pacman.d/mirrorlist\' /etc/pacman.conf

# Additional packages
pacman -Sy mesa libva libxft libxinerama vulkan-radeon lib32-vulkan-radeon xorg-server xorg-xinput xf86-video-amdgpu xf86-video-ati maim xclip noto-fonts yt-dlp python-mutagen imv mpv thunar firefox lxappearance nwg-look ttf-firacode-nerd ffmpegthumbnails ffmpegthumbs tumbler discord qbittorrent ttf-sazanami ttf-baekmuk 

# Install yay
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
cd ..

# Autostart apps
echo "picom &\ndunst &\nslstatus &\nnitrogen --restore \nexec dwm" > .xinitrc
