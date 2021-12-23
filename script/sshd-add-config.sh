#!/bin/bash
LOG=/sshd-add-config_$(date +%Y%m%d-%H%M%S).log
{

echo SSHサーバーを起動するポート番号を設定します
echo （デフォルトでは22です）
read PORTNO
# echo ${PORTNO:-22}
sudo su -c "cat << EOF >> /etc/ssh/sshd_config

###################################################################
PermitRootLogin no
Port ${PORTNO:-22}
PasswordAuthentication no
###################################################################
EOF
systemctl restart sshd"

echo "Finish in "$(date +%Y%m%d-%H%M%S)

}>> >(tee -a ${LOG}) 2>&1
