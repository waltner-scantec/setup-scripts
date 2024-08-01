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
    "https://gitlab.com/scantec-internal/composcan/ai-blox-composcan.git composcan pip"
    "https://gitlab.com/scantec-internal/hardware/rfid.git rfid setup" 
    "https://gitlab.com/scantec-internal/hardware/blox.git blox setup"
    "https://gitlab.com/scantec-internal/pyutil.git pyutil setup"
    "https://gitlab.com/scantec-internal/hardware/maxxvision-cam.git maxxvision-cam setup"
    "https://gitlab.com/scantec-internal/hardware/usb-relay-controller.git usb-relay-controller setup"
    "https://gitlab.com/scantec-internal/hardware/hw-base hw-base setup"
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
    CS_PY_VERSION="3.8"
    CS_ENV_NAME="composcan"

    echo "installing all composcan stuff (python${CS_PY_VERSION}, venv: ${CS_ENV_NAME})"
    setup_python_venv $CS_PY_VERSION $CS_ENV_NAME
    # install all given repositories in $GIT_REPOS_CS into $SW_DIR and the venv "composcan"
    clone_and_install_repos "${GIT_REPOS_CS[@]}" "$SW_DIR" "$CS_ENV_NAME"

    # install/prepare aws
    if ! aws --version > /dev/null 2>&1
    then
	echo "installing aws-cli"
	aws_install_script="/home/ai-blox/software/composcan/scripts/install_awscli.sh"
        sudo chmod +x $aws_install_script
        /bin/bash $aws_install_script
    else
        echo "aws-cli has already been installed"
    fi

    if [ ! -f "${HOME}/.aws/config" ]
    then
        echo "installing aws-cli config"
        mkdir -p $HOME/.aws
        sudo cat <<EOL >> $HOME/.aws/config
[default]
region = eu-central-1
output = json
EOL
    else
        echo "aws-cli config has already been installed"
    fi
    if [ ! -f "${HOME}/.aws/credentials" ]
    then
        echo "installing aws-cli credentials"
        mkdir -p $HOME/.aws
        sudo cat <<EOL >> $HOME/.aws/credentials
[composcan]
aws_access_key_id = <AWS_ACCESS_KEY>
aws_secret_access_key = <AWS_SECRET_ACCESS_KEY>
region = eu-central-1
EOL
        echo "prepared aws-cli, please fill in the credentials in ${HOME}/.aws/credentials accordingly!"
	sleep 3
    else
        echo "aws-cli credentials have already been installed"
    fi

    # add usb relay rule
    usb_relay_rules="99-yamutec-usbrelay.rules"
    if [ ! -f "/etc/udev/rules.d/${usb_relay_rules}" ]
    then
        echo "installing usb relay prerequisites"
        USB_RELAY_DEV_ID="16d0:0d0e"
        if ! lsusb | grep -q "$USB_RELAY_DEV_ID"
        then
            echo "USB relay is either not connected or flashed with wrong firmware! (search for ${USB_RELAY_ID} failed)."
            exit 1
        fi
        sudo aptitude install -y libhidapi-libusb0 libhidapi-dev
        sudo cp "${SW_DIR}/usb-relay-controller/${usb_relay_rules}" "/etc/udev/rules.d/${usb_relay_rules}"
        sudo udevadm control --reload-rules && sudo udevadm trigger
    else
        echo "usb relay prerequisites already installed"
    fi

    # add rfid reader rule
    rfid_rules="99-elatec-rfid-reader.rules"
    if [ ! -f "/etc/udev/rules.d/$rfid_rules" ]
    then
        echo "install rfid prerequisites"
        RFID_READER_DEV_ID="09d8:0420"  # flashed with SimpleProtocol
        if ! lsusb | grep -q "$RFID_READER_DEV_ID"
        then
            echo "RFID reader is either not connected or flashed with wrong firmware! (search for ${RFID_READER_DEV_ID} failed)."
            exit 1
        fi
        sudo cp "${SW_DIR}/rfid/${rfid_rules}" "/etc/udev/rules.d/${rfid_rules}"
        sudo udevadm control --reload-rules && sudo udevadm trigger
    else
        echo "rfid prerequisites already installed"
    fi

    # add polygraphy and tensorrt
    trt_poly_zip_file="https://scantec-file-storage.s3.eu-central-1.amazonaws.com/media/software/blox-py${CS_PY_VERSION}-tensorrt-polygraphy.zip"
    cd && wget -c $trt_poly_zip_file
    unzip $trt_poly_zip_file
    mv polygraphy* tensorrt* "~/venvs/${CS_ENV_NAME}/lib/python${CS_PY_VERSION}/site-packages"
    rm $trt_poly_zip_file

    # prepare configs
    if [ ! -f "${SW_DIR}composcan/cfg/composcan.yaml" ]
    then
        echo "copying configs"
        cp ${SW_DIR}composcan/cfg/composcan.yaml.template ${SW_DIR}composcan/cfg/composcan.yaml
        cp ${SW_DIR}composcan/cfg/cam.yaml.template ${SW_DIR}composcan/cfg/cam.yaml
        echo "DO NOT FORGET TO ADAPT CONFIG FILES IN: ${SW_DIR}composcan/cfgs/!"
        sleep 3
    else
        echo "CompoScan configs already available in: ${SW_DIR}composcan/cfgs/"
    fi

    echo "CompoScan installation complete."

elif [ "$PRODUCT" == "smartscan" ]
then
    SS_PY_VERSION="3.8"
    SS_ENV_NAME="ai-blox"

    echo "installing all SmartScan stuff (python${SS_PY_VERSION}, venv: ${SS_ENV_NAME})"
    setup_python_venv $SS_PY_VERSION $SS_ENV_NAME
    # install all given repositories in $GIT_REPOS_SS into $SW_DIR and the venv $SS_EMV_NAME
    clone_and_install_repos "${GIT_REPOS_SS[@]}" "$SW_DIR" "$SS_ENV_NAME"

    echo "SmartScan installation complete."

fi

