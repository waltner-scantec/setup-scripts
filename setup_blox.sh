#!/bin/bash

# Initialize variables
GIT_NAME=""
GIT_EMAIL=""
SW_DIR=""
BRIDGE_IP=""
HOST_NAME=""

# Function to print usage
usage() {
    echo "Usage: $0 ./setup_blox.sh --git-name=\"First Last\" --git-email=\"f.last@ecotec-scantec.com\" --sw-dir=/home/ai-blox/software/ --bridge=192.168.XXX.10 --host-name=product-company-site"
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
        --bridge=* )
            BRIDGE_IP="${1#*=}"
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
if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ] || [ -z "$SW_DIR" ] || [ -z "$BRIDGE_IP" ] || [ -z "$HOST_NAME" ]; then
    usage
fi

# Validate the bridge address (simple regex for IPv4)
if [[ ! $BRIDGE_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid IP address format."
    exit 1
fi


echo "Starting setup in 10 seconds with the following settings:"
echo "    Hostname: ${HOST_NAME}"
echo "    Git Name: ${GIT_NAME}"
echo "    Git Email: ${GIT_EMAIL}"
echo "    Software base directory: ${SW_DIR}"
echo "    Ethernet Bridge IP: ${BRIDGE_IP}"
sleep 10


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
sudo apt install -y aptitude git zsh vim curl wget tmux

# cache credentials for 90 days
git config --global credential.helper 'cache --timeout=7776000'

# set git config to reflect your identity
git config --global user.email $GIT_EMAIL
git config --global user.name $GIT_NAME

# change default shell to zsh
chsh -s /usr/bin/zsh

# install oh-my-zsh
if [ ! -d "${HOME}/.oh-my-zsh" ]
then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# prepare Vundle for vim plugins
if [ ! -d "${HOME}/.vim/bundle/Vundle.vim" ]
then
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi

# append the network configuration to the /etc/network/interfaces file
if ! grep -q "iface br0" /etc/network/interfaces
then
    sudo cat <<EOL >> /etc/network/interfaces

# setup interfaces
# One bridge to rule them all!
auto br0
iface br0 inet static
    address $BRIDGE_IP
    netmask 255.255.255.0
    bridge_ports eth1 eth2 eth3 eth4
EOL
fi

# create software dir as used for all Blox products (SmartScan, CompoScan)
mkdir -p $SW_DIR

# clone blox repo
cd $SW_DIR
BLOX_DIR=${SW_DIR}/blox
if [ ! -d "${SW_DIR}/blox" ]
then
    git clone https://gitlab.com/scantec-internal/hardware/blox $BLOX_DIR
fi

cd $BLOX_DIR

# add vim config
if [ ! -f "${HOME}/.vimrc" ]
then
    cp vim/.vimrc ${HOME}/.vimrc
fi

# add tmux config
if [ ! -f "${HOME}/.tmux.conf" ]
then
    cp tmux/.tmux.conf ${HOME}/.tmux.conf
fi

# remove unnecessary folders
if [ -d "${HOME}/Documents" ]
then
    rm -rf "${HOME}/Documents"
    rm -rf "${HOME}/Downloads"
    rm -rf "${HOME}/Music"
    rm -rf "${HOME}/Pictures"
    rm -rf "${HOME}/Public"
    rm -rf "${HOME}/Templates"
    rm -rf "${HOME}/Videos"
fi


# print further instructions
echo "NEXT STEPS:"
echo "1) run vim, ignore warnings and then `:PluginInstall`"
echo "2) Setup for CompoScan or SmartScan"
