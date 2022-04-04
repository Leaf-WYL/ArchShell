#!/bin/bash

LOG=/arch-setup_$(date +%Y%m%d-%H%M%S).log
{

### preset #####################################
################################################

echo "Start Install Arch Linux"
fdisk -l | grep "Disk /dev/"
echo -n "Select To Install Disk >> "
read INSTAKKDEV

echo -n "Input for root password >> "
read ROOTPASS

echo "\nCreate User"
echo -n "Input for User Name >> "
read CREATEUSER

echo -n "Input for User Password >> "
read USERPASS

echo -n "\nInput for Hostname >> "
read MACHINENAME

################################################
################################################


### Device Settings ############################
################################################

sgdisk -n "0::+512M" -t 0:ef00 /dev/${INSTAKKDEV}
sgdisk -n "0::" -t 0:8e00 /dev/${INSTAKKDEV}

mkfs.vfat -F32 /dev/${INSTAKKDEV}1
mkfs.ext4 /dev/${INSTAKKDEV}2


echo y | pvcreate /dev/${INSTAKKDEV}2
vgcreate arch /dev/${INSTAKKDEV}2

lvcreate -L 2G -n swap arch
echo y | lvcreate -l 100%FREE -n root arch

mkfs.ext4 /dev/arch/root
mkswap /dev/arch/swap
swapon /dev/arch/swap

mount /dev/arch/root /mnt
mkdir /mnt/boot
mount /dev/${INSTAKKDEV}1 /mnt/boot

yes | pacman -Sy
yes | pacman -S archlinux-keyring

pacstrap /mnt base linux linux-firmware grub dosfstools efibootmgr sudo lvm2
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
sed -i 's/\(keyboard\)/lvm2 \1/g' /etc/mkinitcpio.conf
mkinitcpio -p linux
sed -i '/global {/a\
	use_lvmetad = 0' /etc/lvm/lvm.conf
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch --boot-directory=/boot --recheck --debug
mkdir /boot/EFI/boot
cp /boot/EFI/arch//grubx64.efi /boot/EFI/boot/bootx64.efi
grub-mkconfig -o /boot/grub/grub.cfg
yes ${ROOTPASS} | passwd
useradd -m $CREATEUSER -G wheel
yes ${USERPASS} | passwd $CREATEUSER
sed -i 's/# \(%wheel ALL=(ALL) ALL\)/\1/g' /etc/sudoers
echo ${MACHINENAME} >> /etc/hostname
cat - << EOB >> /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.1.1 ${MACHINENAME}.home ${MACHINENAME}
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
