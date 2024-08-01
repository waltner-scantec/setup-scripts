#!/bin/bash

# import some helper functions
source functions.sh

# declare some variables
CONFIRMATION_SLEEP_SEC=10

# Initialize variables
GIT_NAME=""
GIT_EMAIL=""
SW_DIR=""
HOST_NAME=""

# Check if script is running with sudo privileges
check_sudo

# Function to print usage
usage() {
    echo "Usage: sudo $0 --git-name=\"First Last\" --git-email=\"f.last@ecotec-scantec.com\" --sw-dir=/home/ai-blox/software/ --host-name=product-company-site"
    exit 1
}

# Parse named arguments
while [ "$1" != "" ]; do
    case $1 in
        --git-name=* )
            GIT_NAME="${1#*=}"
            ;;
        --git-email=* )
            GIT_EMAIL="${1#*=}"
            ;;
        --sw-dir=* )
            SW_DIR="${1#*=}"
            ;;
        --host-name=* )
            HOST_NAME="${1#*=}"
            ;;
        * )
            usage
            ;;
    esac
    shift
done

# Check if all required arguments are provided
if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ] || [ -z "$SW_DIR" ] || [ -z "$HOST_NAME" ]; then
    usage
fi


echo "Starting setup in ${CONFIRMATION_SLEEP_SEC} seconds with the following settings:"
echo "    Hostname: ${HOST_NAME}"
echo "    Git Name: ${GIT_NAME}"
echo "    Git Email: ${GIT_EMAIL}"
echo "    Software base directory: ${SW_DIR}"
sleep $CONFIRMATION_SLEEP_SEC

echo "!!! changing ownership of home..."
sudo chown -R ai-blox:ai-blox /home/a-blox/

echo "!!! setting locale..."
set_locale

# Set the hostname if not already set
CURRENT_HOSTNAME=$(hostname)
if [ "$CURRENT_HOSTNAME" != "$HOST_NAME"  ]
then
    echo "!!! setting hostname to: ${HOST_NAME}"
    sudo hostnamectl set-hostname "$HOST_NAME"
    echo "Hostname set to $HOST_NAME"
else
    echo "!!! hostname was already set to: ${HOST_NAME}"
fi

echo "!!! installing prerequisites..."
# update system
sudo apt-get update

# install prerequisites
sudo apt install -y aptitude git zsh vim libcurl4 curl wget tmux nano htop tree

echo "!!! configuring git..."
# cache credentials for 90 days
sudo -u ai-blox git config --global credential.helper 'cache --timeout=7776000'

# set git config to reflect your identity
sudo -u ai-blox git config --global user.email $GIT_EMAIL
sudo -u ai-blox git config --global user.name $GIT_NAME

echo "!!! installing zsh..."
# change default shell to zsh
sudo -u ai-blox chsh -s /usr/bin/zsh

# install oh-my-zsh
if [ ! -d "${HOME}/.oh-my-zsh" ]
then
    echo "!!! installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "!!! oh-my-zsh has already been installed..."
fi

# prepare Vundle for vim plugins
if [ ! -d "${HOME}/.vim/bundle/Vundle.vim" ]
then
    echo "!!! preparing vim..."
    sudo -u ai-blox git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
else
    echo "!!! vim was already prepared..."
fi

# append the network configuration to the /etc/network/interfaces file
if ! grep -q "iface br0" /etc/network/interfaces
then
    echo "!!! setting network configuration (br0)..."
    sudo cat <<EOL >> /etc/network/interfaces
# setup ethernet interfaces
# two bridges to rule them all!

# SmartScan bridge
auto br0
iface br0 inet static
    address 192.168.200.10
    netmask 255.255.255.0
    bridge_ports eth1 eth2 eth3 eth4
    # with 4 cameras, eth0 needs to be added to brigde (comment the above line)
    # bridge_ports eth1 eth2 eth3 eth4 eth0
    bridge_stp off
    bridge_fd 0
    bridge_maxwait 0

# CompoScan bridge
auto br0:1
iface br0:1 inet static
    address 192.168.100.10
    netmask 255.255.255.0

# DHCP configuration for red side (setup)
auto eth0
iface eth0 inet dhcp
# or static if it needs to be added to brigde (comment the above two lines)
# iface eth0 inet manual

# other PoE ports
iface eth1 inet manual
iface eth2 inet manual
iface eth3 inet manual
iface eth4 inet manual
EOL
    echo "MAKE SURE TO DISABLE THE MODEM IN /etc/network/interfaces UNTIL THE SETUP IS COMPLETE TO AVOID ROUTING ISSUES (NO INTERNET CONNECTIVITY)!"
    sleep 3
else
    echo "!!! network configuration (br0) has already been set..."
fi

# create software dir as used for all Blox products (SmartScan, CompoScan)
if [ ! -d "${SW_DIR}" ]
then
    echo "!!! setting up SW_DIR (${SW_DIR})..."
    sudo -u ai-blox mkdir -p $SW_DIR
else
    echo "!!! SW_DIR (${SW_DIR}) has already been created..."
fi

# add user to group gpio
sudo usermod -aG gpio ai-blox

# python3.8
if command -v python3.8 &>/dev/null; then
    echo "!!! python3.8 has already been installed..."
else
    echo "!!! installing python3.8..."
    sudo aptitude install -y python3.8 python3.8-pip python3.8-venv
    sudo pip3 install --upgrade pip
    sudo pip3 install --upgrade pip
fi

echo "!!! setting Jetson performance to max mode (20W, 6 core)..."
# set Xavier NX mode to max performance (20W, 6 core)
sudo nvpmodel -m 8

echo "!!! installing jetson-stats (jtop command)"
# install jetson-stats
sudo pip3 install -U jetson-stats

# clone blox repo
cd $SW_DIR
BLOX_DIR="${SW_DIR}/blox"
if [ ! -d "${BLOX_DIR}" ]
then
    echo "!!! cloning blox repo into ${SW_DIR}..."
    sudo -u ai-blox git clone https://gitlab.com/scantec-internal/hardware/blox "${BLOX_DIR}"
else
    echo "!!! blox repo was already cloned into ${SW_DIR}..."
fi

cd "${BLOX_DIR}"

# add vim config
if [ ! -f "${HOME}/.vimrc" ]
then
    echo "!!! adding .vimrc and installing vim plugins..."
    sudo -u ai-blox cp vim/.vimrc ${HOME}/.vimrc
    sudo -u ai-blox vim +PluginInstall +qall
else
    echo "!!! .vimrc available and vim plugins have already been installed..."

fi

# add tmux config
if [ ! -f "${HOME}/.tmux.conf" ]
then
    echo "!!! installing .tmux.conf..."
    sudo -u ai-blox cp tmux/.tmux.conf ${HOME}/.tmux.conf
else
    echo "!!! .tmux.conf has already been installed..."
fi

# remove unnecessary folders
if [ -d "${HOME}/Documents" ]
then
    echo "!!! removing unneeded folders..."
    sudo -u ai-blox rm -rf "${HOME}/Documents"
    sudo -u ai-blox rm -rf "${HOME}/Downloads"
    sudo -u ai-blox rm -rf "${HOME}/Music"
    sudo -u ai-blox rm -rf "${HOME}/Pictures"
    sudo -u ai-blox rm -rf "${HOME}/Public"
    sudo -u ai-blox rm -rf "${HOME}/Templates"
    sudo -u ai-blox rm -rf "${HOME}/Videos"
fi

# install MVS
if [ ! -d "/opt/MVS/" ]
then
    echo "!!! installing MVS..."
    install_mvs "${BLOX_DIR}"
else
    echo "!!! MVS has already been installed..."
fi

