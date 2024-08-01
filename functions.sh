#!/bin/bash

# Define the locale
LOCALE="en_US.UTF-8"
ENV_FILE="/etc/environment"
PROFILE_SCRIPT="/etc/profile.d/locale.sh"
SUDOERS_FILE="/etc/sudoers"

# Function to set locale
function set_locale {
    # Execute functions
    update_etc_environment
    create_locale_script
    update_sudoers

    echo "Locale settings have been updated system-wide."
    # export LC_ALL="en_US.UTF-8"
    # export LC_CTYPE="en_US.UTF-8"
    # sudo dpkg-reconfigure locales
}

# Function to update /etc/environment
update_etc_environment() {
    echo "Updating /etc/environment..."
    if ! grep -q 'LANG=' "$ENV_FILE"; then
        sudo sh -c "echo 'LANG=\"$LOCALE\"' >> $ENV_FILE"
    else
        echo "LANG is already set in $ENV_FILE"
    fi

    if ! grep -q 'LANGUAGE=' "$ENV_FILE"; then
        sudo sh -c "echo 'LANGUAGE=\"$LOCALE\"' >> $ENV_FILE"
    else
        echo "LANGUAGE is already set in $ENV_FILE"
    fi

    if ! grep -q 'LC_ALL=' "$ENV_FILE"; then
        sudo sh -c "echo 'LC_ALL=\"$LOCALE\"' >> $ENV_FILE"
    else
        echo "LC_ALL is already set in $ENV_FILE"
    fi
}

# Function to create script in /etc/profile.d
create_locale_script() {
    if [ ! -f "$PROFILE_SCRIPT" ]; then
        echo "Creating $PROFILE_SCRIPT..."
        sudo sh -c "echo '#!/bin/sh' > $PROFILE_SCRIPT"
        sudo sh -c "echo 'export LANG=\"$LOCALE\"' >> $PROFILE_SCRIPT"
        sudo sh -c "echo 'export LANGUAGE=\"$LOCALE\"' >> $PROFILE_SCRIPT"
        sudo sh -c "echo 'export LC_ALL=\"$LOCALE\"' >> $PROFILE_SCRIPT"
        sudo chmod +x "$PROFILE_SCRIPT"
    else
        echo "$PROFILE_SCRIPT already exists"
    fi
}

# Function to update sudoers file
update_sudoers() {
    echo "Updating sudoers file..."
    if ! sudo grep -q 'Defaults env_keep += "LANG LANGUAGE LC_ALL"' "$SUDOERS_FILE"
    then
        sudo sh -c "echo 'Defaults env_keep += \"LANG LANGUAGE LC_ALL\"' >> $SUDOERS_FILE"
    else
        echo "sudoers file already contains the required environment keep settings"
    fi
}

# Function to check if script is running with sudo privileges
function check_sudo {
    if [ "$(id -u)" != "0" ]
    then
        echo "This script must be run with sudo privileges."
	exit 1
fi
}

# Function to setup Python virtual environment
setup_python_venv() {
    local python_version="$1"
    local venv_name="$2"
    local venv_dir="$HOME/venvs/$venv_name"

    # Check if Python 3.8 is installed
    if ! command -v "python${python_version}" &> /dev/null; then
        echo "Python ${python_version} is not installed. Installing..."
        # Install Python 3.x and python3-venv package
        sudo apt update
        sudo apt install -y "python${python_version}"
        sudo apt install -y python3-pip python3-venv
        sudo apt install -y python3-venv
        sudo apt install -y "python${python_version}-venv"
	sudo pip3 install --upgrade pip
    fi

    # Create virtual environment if not already exists
    if [ ! -d "$venv_dir" ]; then
        echo "Creating Python virtual environment '$venv_name' using Python $python_version..."
        echo "Running: sudo -u ai-blox python${python_version} -m venv --system-site-packages $venv_dir"
        sudo -u ai-blox "python${python_version}" -m venv --system-site-packages "$venv_dir"
        echo "Virtual environment '$venv_name' created."
        source "${venv_dir}/bin/activate"
        echo "Virtual environment '$venv_name' activated."
	python3 -m pip install --upgrade pip --no-cache-dir
	echo "pip updated."
        echo "Setting up virtual environment '$venv_name' done."
    else
        echo "Virtual environment '$venv_name' already exists."
    fi
}

# Function to clone repository, install package, and return to initial directory
function clone_and_install_repo {
    local repo_url=$1
    local target_folder=$2
    local install_type=$3
    local venv_name=$4
    local venv_dir="$HOME/venvs/$venv_name"

    echo "clone_and_install_repo"
    echo "repo: $repo_url"
    echo "target folder: $target_folder"
    echo "install type: $install_type"
    echo "venv: $venv_name ($venv_dir)"
    return

    # Check if target folder already exists
    if [ ! -d "$target_folder" ]
    then
        # Clone repository
        echo "sudo -u ai-blox git clone $repo_url $folder_name"
        return
        sudo -u ai-blox git clone $repo_url $folder_name
        if [ $? -ne 0 ]; then
            echo "Failed to clone $repo_url. Exiting."
            exit 1
        fi
    fi

    # Enter repository directory
    cd $folder_name || exit
    if [ $? -ne 0 ]; then
        echo "Failed to enter directory $folder_name. Exiting."
        exit 1
    fi

    # activate venv
    if [ ! -f "$venv_dir/bin/activate" ]
    then
        echo "Failed to find $venv_dir/bin/activate. Exiting."
	exit 1
    fi
    echo "source ${venv_dir}/bin/activate"
    source "${venv_dir}/bin/activate"

    # Install the Python package
    if [ "$install_type" == "pip" ]
    then
        pip install -r requirements.txt
    elif [ "$install_type" == "setup" ]
    then
	pip install -e .
    else
        echo "Unknown install type: $install_type"
	exit 1
    fi
    if [ $? -ne 0 ]; then
        echo "Failed to install package in $folder_name. Exiting."
        exit 1
    fi

    # Return to initial directory
    cd - > /dev/null
}

# Function to clone repositories and install them into base_folder
function clone_and_install_repos {
    local repositories=("${@:1:$#-2}")
    local base_folder="${@:(-2):1}"      # Second to last argument is base_folder
    local venv_name="${@:(-1)}"          # Last argument is venv_name

    # Iterate over repositories
    echo "base_folder: ${base_folder}"
    echo "venv_name: ${venv_name}"
    echo "repos: ${repositories[@]}"

    for repo_info in "${repositories[@]}"; do
	# printf "\n\n$repo_info\n"
        repo_url=$(echo "$repo_info" | cut -d ' ' -f 1)
	folder_name=$(echo "$repo_info" | cut -d ' ' -f 2)
	install_type=$(echo "$repo_info" | cut -d ' ' -f 3)
	target_folder="$base_folder$folder_name"

	printf "\n\nCloning and installing $repo_url into $target_folder...\n"
	clone_and_install_repo $repo_url $target_folder $install_type $venv_name
	echo "Finished cloning and installing $repo_url."
    done
    echo "All repositories cloned and installed successfully."
}

# Function to install MVS
function install_mvs {
    check_sudo

    local blox_folder=$1
    local mvs_file="MVS-2.1.2_aarch64_20230531.deb"

    target_folder="/opt/MVS/"
    # Check if MVS folder already exists
    if [ -d "$target_folder" ]
    then
        echo "Folder $target_folder already exists. Skipping installation."
        return
    fi
    # Check if environment variables are set and script for that is available
    if [ ! -d "$blox_folder" ]
    then
        echo "Folder $blox_folder does not exist. Needed for setting environment variables. Skipping installation."
        return
    fi

    cd $blox_folder
    echo "\nDownloading MVS from AWS S3..."
    wget -c "https://sceda-resources.s3.eu-central-1.amazonaws.com/MVS/${mvs_file}"

    echo "\nInstalling MVS..."
    dpkg -i $mvs_file

    echo "\nSetting environment variables..."
    bash "${blox_folder}/scripts/add_mvs_env_vars_to_shell_aarch64.sh"

    # cleanup
    echo "removing ${blox_folder}/${mvs_file}"

    rm ${mvs_file}
}
