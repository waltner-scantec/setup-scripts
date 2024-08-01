#!/bin/bash

# import some helper functions
source functions.sh

# define repositories for product
# must be in the form: url target-folder install-type
# where:
#  url: gitlab/github url
#  target-folder: subfolder in $SW_DIR to clone into
#  install-type: pip (requirements.txt) or setup (setup.py)
GIT_REPOS_CS=(
    "https://gitlab.com/scantec-internal/composcan/ai-blox-composcan.git ai-blox-composcan pip"
    "https://gitlab.com/scantec-internal/hardware/rfid.git rfid setup" 
    "https://gitlab.com/scantec-internal/hardware/blox.git blox setup"
    "https://gitlab.com/scantec-internal/pyutil.git pyutil setup"
    "https://gitlab.com/scantec-internal/hardware/maxxvision-cam.git maxxvision-cam setup"
    "https://gitlab.com/scantec-internal/hardware/usb-relay-controller.git usb-relay-controller setup"
)
GIT_REPOS_SS=(
    "https://gitlab.com/scantec-internal/smartscan/ai-blox-smartscan.git ai-blox pip"
)


# Initialize variables
PRODUCT=""
GIT_EMAIL=""
SW_DIR=""

# Function to print usage
usage() {
    echo "Usage: $0 --git-email=\"f.last@ecotec-scantec.com\" --sw-dir=/home/ai-blox/software/ --product=composcan|smartscan"
    exit 1
}

# Parse named arguments
while [ "$1" != "" ]; do
    case $1 in
        --git-email=* )
            GIT_EMAIL="${1#*=}"
            ;;
        --sw-dir=* )
            SW_DIR="${1#*=}"
            ;;
        --product=* )
            PRODUCT="${1#*=}"
            ;;
        * )
            usage
            ;;
    esac
    shift
done

# Check if all required arguments are provided
if [ -z "$GIT_EMAIL" ] || [ -z "$SW_DIR" ] || [ -z "$PRODUCT" ]; then
    usage
fi
if [ ! -d "${SW_DIR}" ]
then
    echo "The base directory does not exist. Make sure you install the blox (https://gitlab.com/scantec-internal/hardware/blox) requirements first, that should create this folder! Otherwise, the provided argument \"--sw-dir=${SW_DIR}\" might not be correct"
    exit -1
fi


echo "Starting \"${PRODUCT}\" setup in 5 seconds with the following settings:"
echo "    Git Email: ${GIT_EMAIL}"
echo "    Software base directory: ${SW_DIR}"
echo "!!! BEWARE: ONGOING WORK !!!"
sleep 0


# # update system
# sudo apt-get update


# clone repos for product and run install
if [ "$PRODUCT" == "composcan" ]
then
    echo "install all composcan stuff"
    setup_python_venv 3.8 composcan
    # install all given repositories in $GIT_REPOS_CS into $SW_DIR and the venv "composcan"
    clone_and_install_repos "${GIT_REPOS_CS[@]}" "$SW_DIR" "composcan"
    # TODO install/prepare aws
    # ...
    echo "CompoScan install done."
elif [ "$PRODUCT" == "smartscan" ]
then
    echo "install all smartscan stuff"
    setup_python_venv 3.8 ai-blox
    # install all given repositories in $GIT_REPOS_SS into $SW_DIR and the venv "ai-blox"
    clone_and_install_repos "${GIT_REPOS_SS[@]}" "$SW_DIR" "ai-blox"
    echo "SmartScan install done."
fi

