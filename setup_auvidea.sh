#!/bin/bash

# import some helper functions
source functions.sh

USERNAME="ai-blox"
USERHOME=$(eval echo ~$USERNAME)
SW_DIR="$USERHOME/software"

# # declare some variables
# CONFIRMATION_SLEEP_SEC=10
# 
# # Initialize variables
# GIT_NAME=""
# GIT_EMAIL=""
# SW_DIR=""
# HOST_NAME=""
 
# Check if script is running with sudo privileges
check_sudo
 
# # Function to print usage
# usage() {
#     echo "Usage: sudo $0 --git-name=\"First Last\" --git-email=\"f.last@ecotec-scantec.com\" --sw-dir=/home/$USERNAME/software/ --host-name=product-company-site"
#     exit 1
# }
# 
# # Parse named arguments
# while [ "$1" != "" ]; do
#     case $1 in
#         --git-name=* )
#             GIT_NAME="${1#*=}"
#             ;;
#         --git-email=* )
#             GIT_EMAIL="${1#*=}"
#             ;;
#         --sw-dir=* )
#             SW_DIR="${1#*=}"
#             ;;
#         --host-name=* )
#             HOST_NAME="${1#*=}"
#             ;;
#         * )
#             usage
#             ;;
#     esac
#     shift
# done
# 
# # Check if all required arguments are provided
# if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ] || [ -z "$SW_DIR" ] || [ -z "$HOST_NAME" ]; then
#     usage
# fi
# 
# 
# echo "Starting setup in ${CONFIRMATION_SLEEP_SEC} seconds with the following settings:"
# echo "    Hostname: ${HOST_NAME}"
# echo "    Git Name: ${GIT_NAME}"
# echo "    Git Email: ${GIT_EMAIL}"
# echo "    Software base directory: ${SW_DIR}"
# sleep $CONFIRMATION_SLEEP_SEC
# 
# echo "!!! changing ownership of home..."
# sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/
# 
# echo "!!! setting locale..."
# set_locale
# 
# # Set the hostname if not already set
# CURRENT_HOSTNAME=$(hostname)
# if [ "$CURRENT_HOSTNAME" != "$HOST_NAME"  ]
# then
#     echo "!!! setting hostname to: ${HOST_NAME}"
#     sudo hostnamectl set-hostname "$HOST_NAME"
#     echo "Hostname set to $HOST_NAME"
# else
#     echo "!!! hostname was already set to: ${HOST_NAME}"
# fi
# 
echo "!!! installing prerequisites..."
# update system
sudo apt-get update
# 
# install prerequisites
sudo apt install -y aptitude git zsh vim libcurl4 curl wget tmux nano htop tree
 
# echo "!!! configuring git..."
# # cache credentials for 90 days
# sudo -u $USERNAME git config --global credential.helper 'cache --timeout=7776000'
# 
# # set git config to reflect your identity
# sudo -u $USERNAME git config --global user.email $GIT_EMAIL
# sudo -u $USERNAME git config --global user.name $GIT_NAME
# 
echo "!!! installing zsh..."
# change default shell to zsh
sudo -u $USERNAME chsh -s /usr/bin/zsh

# install oh-my-zsh
if [ ! -d "${USERHOME}/.oh-my-zsh" ]
then
    echo "!!! installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "!!! oh-my-zsh has already been installed..."
fi

# prepare Vundle for vim plugins
if [ ! -d "${USERHOME}/.vim/bundle/Vundle.vim" ]
then
    echo "!!! preparing vim..."
    sudo -u $USERNAME git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
else
    echo "!!! vim was already prepared..."
fi

# set up the bridge using the NetworkManager
if ! grep -q "iface br0" /etc/network/interfaces
then
    echo "!!! setting network configuration (br0)..."
    sudo nmcli connection add type bridge ifname br0 con-name br0
    sudo nmcli connection modify br0 ipv4.addresses 192.168.200.10/24 ipv4.method manual
    sudo nmcli connection add type bridge-slave ifname enP1p3s0 master br0
    sudo nmcli connection add type bridge-slave ifname enP1p4s0 master br0
    sudo nmcli connection add type bridge-slave ifname enP1p5s0 master br0
    sudo nmcli connection add type bridge-slave ifname enP1p6s0 master br0
    sudo nmcli connection up br0
else
    echo "!!! network configuration (br0) has already been set..."
fi

# create software dir as used for all Blox products (SmartScan, CompoScan)
if [ ! -d "${SW_DIR}" ]
then
    echo "!!! setting up SW_DIR (${SW_DIR})..."
    sudo -u $USERNAME mkdir -p $SW_DIR
else
    echo "!!! SW_DIR (${SW_DIR}) has already been created..."
fi

# add user to group gpio
sudo usermod -aG gpio $USERNAME

# # python3.8
# if command -v python3.8 &>/dev/null; then
#     echo "!!! python3.8 has already been installed..."
# else
#     echo "!!! installing python3.8..."
#     sudo aptitude install -y python3.8 python3.8-pip python3.8-venv
#     sudo pip3 install --upgrade pip
#     sudo pip3 install --upgrade pip
# fi
# 
echo "!!! setting Jetson performance to max mode (20W, 6 core)..."
# set Orin NX mode to max performance (25W, 8 core)
sudo nvpmodel -m 0

echo "!!! installing jetson-stats (jtop command)"
# install jetson-stats
sudo pip3 install -U jetson-stats

# clone blox repo
cd $SW_DIR
BLOX_DIR="${SW_DIR}/blox"
if [ ! -d "${BLOX_DIR}" ]
then
    echo "!!! cloning blox repo into ${SW_DIR}..."
    sudo -u $USERNAME git clone https://gitlab.com/scantec-internal/hardware/blox "${BLOX_DIR}"
else
    echo "!!! blox repo was already cloned into ${SW_DIR}..."
fi

cd "${BLOX_DIR}"

# add vim config
if [ ! -f "${USERHOME}/.vimrc" ]
then
    echo "!!! adding .vimrc and installing vim plugins..."
    sudo -u $USERNAME cp vim/.vimrc ${USERHOME}/.vimrc
    sudo -u $USERNAME vim +PluginInstall +qall
else
    echo "!!! .vimrc available and vim plugins have already been installed..."

fi

# add tmux config
if [ ! -f "${USERHOME}/.tmux.conf" ]
then
    echo "!!! installing .tmux.conf..."
    sudo -u $USERNAME cp tmux/.tmux.conf ${USERHOME}/.tmux.conf
else
    echo "!!! .tmux.conf has already been installed..."
fi

# # remove unnecessary folders
# if [ -d "${USERHOME}/Documents" ]
# then
#     echo "!!! removing unneeded folders..."
#     sudo -u $USERNAME rm -rf "${USERHOME}/Documents"
#     sudo -u $USERNAME rm -rf "${USERHOME}/Downloads"
#     sudo -u $USERNAME rm -rf "${USERHOME}/Music"
#     sudo -u $USERNAME rm -rf "${USERHOME}/Pictures"
#     sudo -u $USERNAME rm -rf "${USERHOME}/Public"
#     sudo -u $USERNAME rm -rf "${USERHOME}/Templates"
#     sudo -u $USERNAME rm -rf "${USERHOME}/Videos"
# fi
# 
# install MVS
if [ ! -d "/opt/MVS/" ]
then
    echo "!!! installing MVS..."
    install_mvs "${BLOX_DIR}"
else
    echo "!!! MVS has already been installed..."
fi

