#!/bin/bash

LOG=/arch-setup_$(date +%Y%m%d-%H%M%S).log
{

### preset #####################################
################################################
lsblk
echo "Select To Install Disk For Arch Linux"
read INSTAKKDEV

echo "Input for root password"
read ROOTPASS

echo "Create User"
echo "Input for User Name"
read CREATEUSER

echo "Input for User Password"
read USERPASS

echo "Input for Hostname"
read MACHINENAME

################################################
################################################


### Device Settings ############################
################################################

sgdisk -n "0::+512M" -t 0:ef00 ${INSTAKKDEV}
sgdisk -n "0::+512M" -t 0:ef02 ${INSTAKKDEV}
sgdisk -n "0::-2G"  ${INSTAKKDEV}
sgdisk -n "0::" -t 0:8200 ${INSTAKKDEV}

mkfs.vfat -F32 ${INSTAKKDEV}1
echo y | mkfs.ext4 ${INSTAKKDEV}2
echo y | mkfs.ext4 ${INSTAKKDEV}3
mkswap ${INSTAKKDEV}4
swapon ${INSTAKKDEV}4

mount ${INSTAKKDEV}3 /mnt
mkdir /mnt/boot
mount ${INSTAKKDEV}2 /mnt/boot
mkdir /mnt/boot/efi
mount ${INSTAKKDEV}1 /mnt/boot/efi

pacstrap /mnt base linux linux-firmware grub dosfstools efibootmgr sudo
pacstrap /mnt base-devel git go
pacstrap /mnt nano openssh networkmanager dnsutils polkit openssh zsh grml-zsh-config

genfstab -U /mnt >> /mnt/etc/fstab

################################################
################################################


#### Arch chroot ###############################
################################################
arch-chroot /mnt << EOA


### Config Settings ############################

echo exec arch-chroot
echo KEYMAP=jp106 >> /etc/vconsole.conf
sed -i 's/#\(en_US.UTF-8\)/\1/g' /etc/locale.gen
sed -i 's/#\(ja_JP.UTF-8\)/\1/g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
hwclock –systohc –utc
mkinitcpio -p linux
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch --boot-directory=/boot/efi/EFI --recheck --debug
grub-mkconfig -o /boot/efi/EFI/grub/grub.cfg
yes ${ROOTPASS} | passwd
useradd -m $CREATEUSER -G wheel
yes ${USERPASS} | passwd $CREATEUSER
sed -i 's/# \(%wheel ALL=(ALL) ALL\)/\1/g' /etc/sudoers
echo ${MACHINENAME} >> /etc/hostname
cat - << EOB >> /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.0.1 ${MACHINENAME}.home ${MACHINENAME}
EOB
systemctl enable NetworkManager
systemctl enable sshd
pacman -Syu
chsh -s $(which zsh)
################################################


### yay install ################################

mkdir /aur-dir/
cd /aur-dir
git clone https://aur.archlinux.org/yay.git
cd yay
chmod -R 777 /aur-dir/
su ${CREATEUSER} -c 'makepkg -s'
echo Y | pacman -U \$(ls /aur-dir/yay | grep pkg.tar)
rm -rf /aur-dir; cd /

################################################

EOA


################################################
################################################

echo "Finish in "$(date +%Y%m%d-%H%M%S)
}>> >(tee -a ${LOG}) 2>&1

cp ${LOG} /mnt/

shutdown -r now
