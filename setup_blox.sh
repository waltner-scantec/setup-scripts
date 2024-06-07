#!/bin/bash

# Initialize variables
GIT_NAME=""
GIT_EMAIL=""
SW_DIR=""
BRIDGE_IP=""

# Function to print usage
usage() {
    echo "Usage: $0 --git-name=\"NAME\" --git-email=\"EMAIL\" --sw-dir=DIR --bridge=IP_ADDRESS"
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
        * )
            usage
            ;;
    esac
    shift
done

# Check if all required arguments are provided
if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ] || [ -z "$SW_DIR" ] || [ -z "$BRIDGE_IP" ]; then
    usage
fi

# Validate the bridge address (simple regex for IPv4)
if [[ ! $BRIDGE_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid IP address format."
    exit 1
fi


echo "Starting setup in 5 seconds with the following settings:"
echo "    Git Name: ${GIT_NAME}"
echo "    Git Email: ${GIT_EMAIL}"
echo "    Software base directory: ${SW_DIR}"
echo "    Ethernet Bridge IP: ${BRIDGE_IP}"

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
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# prepare Vundle for vim plugins
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

# append the network configuration to the /etc/network/interfaces file
sudo cat <<EOL >> /etc/network/interfaces

# setup interfaces
# One bridge to rule them all!
auto br0
iface br0 inet static
    address $BRIDGE_IP
    netmask 255.255.255.0
    bridge_ports eth1 eth2 eth3 eth4
EOL

# create software dir as used for all Blox products (SmartScan, CompoScan)
mkdir -p $SW_DIR

# clone blox repo
cd $SW_DIR
git clone https://gitlab.com/scantec-internal/hardware/blox
cd blox

# add vim config
cp vim/.vimrc ${HOME}/.vimrc

# add tmux config
cp tmux/.tmux.conf ${HOME}/.tmux.conf
