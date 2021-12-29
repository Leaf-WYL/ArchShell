#!/bin/bash

### sudoを使いすぎて気持ち悪いので、案が思いついたら更新予定 ###

KMSCONFIG=$(cat << EOA
<?xml version="1.0"?>\n
\n
<!-- source：https://wiki.archlinux.jp/index.php/KMSCON -->\n
\n
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">\n
<fontconfig>\n
<match>\n\t
        <test name="family"><string>monospace</string></test>\n\t
        <edit name="family" mode="prepend" binding="strong">\n\t\t
                <string>DejaVu Sans Mono</string>\n\t\t
                <string>IPAGothic</string>\n\t
        </edit>\n
</match>\n
</fontconfig>
EOA
)

echo -e ${KMSCONFIG} | sudo tee -a /etc/fonts/conf.d/99-kmscon.conf
yes Y | sudo pacman -Syu kmscon otf-ipafont ttf-dejavu
sudo systemctl disable getty@tty1.service
sudo systemctl enable kmsconvt@tty1.service
sudo ln -s /usr/lib/systemd/system/kmsconvt\@.service /etc/systemd/system/autovt\@.service

sudo mkdir /etc/kmscon/
echo xkb-layout=jp | sudo tee /etc/kmscon/kmscon.conf

sudo cp /etc/locale.conf /etc/backup_locale.conf
echo LANG=ja_JP.UTF-8 | sudo tee /etc/locale.conf

sudo shutdown -r now


#########################################################################################
## KMSCONFIGについて ##
# 引用元：https://wiki.archlinux.jp/index.php/KMSCON
# 引用元に掲載されているの設定内容。設定はXMLで記載されている。
# /etc/fonts/conf.d/99-kmscon.conf に保存する。
#
#
# pacman -Syu kmscon otf-ipafont ttf-dejavu
# 必要パッケージのインストール。
#
# kmscon：ターミナルエミュレータ。ArchLinuxのデフォルトのカーネルはマルチバイトに未対応。
#       　そのため、KMSCONを使用する。
# otf-ipafont：オープンソースのフォント。IPA（情報処理推進機構）が管理しているため安全（多分）。
# ttf-dejavu：Ubuntsuで使用されているフォント。
#
#
# systemctl disable getty@tty1.service
# systemctl enable kmsconvt@tty1.service
#
# ※この設定は再起動後に有効化される※
# ArchLinuxはデフォルトでgettyがenableになっている。
# このままだとKMSCONと競合するため、gettyをdisableする。
# その後、KMSCONのサービス（kmsconvt）をenableする。
# この設定を行わない場合、tty1のみgettyを使う仕様になる。
# 作業ユーザーがtty1を使っていない場合意味がないかも。
# who am i で確認ができる。
# もし再起動後にgettyのままだった場合は、ttyは１～７まであるので確認してみること。
#
#
# ln -s /usr/lib/systemd/system/kmsconvt\@.service /etc/systemd/system/autovt\@.service
#
# 全ユーザーのログインでKMSCONを使用するように設定を変更する。
#
#
# mkdir /etc/kmscon/
# echo "xkb-layout=jp" >> /etc/kmscon/kmscon.conf
#
# KMSCONはデフォルトで英字配列のため、日本語配列に変更する。
#
#
# tee /etc/locale.conf
#
# このファイルは端末のローカル情報を定義しているファイルです。
# デフォルトではマルチバイト文字が使用不可のため、多くの場合にはLANG=CやLANG=en_US.UTF-8などで
# 設定されている。ja_JP.UTF-8へ変更することで、ArchLinuxが日本語で表示してくれるようになる。
# 
#########################################################################################xxx
