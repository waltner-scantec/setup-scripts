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
    echo "Usage: sudo $0 ./setup_blox.sh --git-name=\"First Last\" --git-email=\"f.last@ecotec-scantec.com\" --sw-dir=/home/ai-blox/software/ --host-name=product-company-site"
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


set_locale

# Set the hostname if not already set
CURRENT_HOSTNAME=$(hostname)
if [ "$CURRENT_HOSTNAME" != "$HOST_NAME"  ]
then
    sudo hostnamectl set-hostname "$HOST_NAME"
    echo "Hostname set to $HOST_NAME"
fi

# update system
sudo apt-get update

# install prerequisites
sudo apt install -y aptitude git zsh vim libcurl4 curl wget tmux nano htop tree

# cache credentials for 90 days
sudo -u ai-blox git config --global credential.helper 'cache --timeout=7776000'

# set git config to reflect your identity
sudo -u ai-blox git config --global user.email $GIT_EMAIL
sudo -u ai-blox git config --global user.name $GIT_NAME

# change default shell to zsh
sudo -u ai-blox chsh -s /usr/bin/zsh

# install oh-my-zsh
if [ ! -d "${HOME}/.oh-my-zsh" ]
then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# prepare Vundle for vim plugins
if [ ! -d "${HOME}/.vim/bundle/Vundle.vim" ]
then
    sudo -u ai-blox git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi

# append the network configuration to the /etc/network/interfaces file
if ! grep -q "iface br0" /etc/network/interfaces
then
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
fi

# create software dir as used for all Blox products (SmartScan, CompoScan)
sudo -u ai-blox mkdir -p $SW_DIR

# clone blox repo
cd $SW_DIR
BLOX_DIR="${SW_DIR}/blox"
if [ ! -d "${BLOX_DIR}" ]
then
    sudo -u ai-blox git clone https://gitlab.com/scantec-internal/hardware/blox "${BLOX_DIR}"
fi

cd "${BLOX_DIR}"

# add vim config
if [ ! -f "${HOME}/.vimrc" ]
then
    sudo -u ai-blox cp vim/.vimrc ${HOME}/.vimrc
    sudo -u ai-blox vim +PluginInstall +qall

fi

# add tmux config
if [ ! -f "${HOME}/.tmux.conf" ]
then
    sudo -u ai-blox cp tmux/.tmux.conf ${HOME}/.tmux.conf
fi

# remove unnecessary folders
if [ -d "${HOME}/Documents" ]
then
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
    install_mvs "${BLOX_DIR}"
fi
