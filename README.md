# SCANTEC Setup-scripts
This repository contains some scripts to ease the setup of AI-Blox devices.

**Beware, that for using this repository in the intended way, it needs to be public. Do not commit any sensitive content to this repository!**

## Basic Blox Setup
To get a minimal default working Blox setup, use the setup_blox.sh Script to get going:
```shell
wget -c https://raw.githubusercontent.com/waltner-scantec/setup-scripts/main/setup_blox.sh
chmod +x setup_blox.sh
./setup_blox.sh --git-name="First Last" --git-email="f.last@ecotec-scantec.com" --sw-dir=/home/ai-blox/software/ --bridge=192.168.XXX.10 --hostname=product-company-site
```

## SmartScan Setup
TODO

## CompoScan Setup
TODO
