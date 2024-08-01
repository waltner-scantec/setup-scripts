# SCANTEC Setup-scripts
This repository contains some scripts to ease the setup of AI-Blox devices.

**Beware, that for using this repository in the intended way, it needs to be public. Do not commit any sensitive content to this repository!**

## Basic Blox Setup
To get a minimal default working Blox setup, use the [`setup_blox.sh`](./setup_blox.sh) script to get going. The script uses some generic functions that are placed inside [`functions.sh`](./functions.sh):
```shell
wget -c https://raw.githubusercontent.com/waltner-scantec/setup-scripts/main/functions.sh
wget -c https://raw.githubusercontent.com/waltner-scantec/setup-scripts/main/setup_blox.sh
chmod +x setup_blox.sh
sudo ./setup_blox.sh --git-name="First Last" --git-email="f.last@ecotec-scantec.com" --sw-dir=/home/ai-blox/software/ --host-name=product-company-site
```

## SmartScan Setup
Use the [`setup_product.sh`](./setup_product.sh) script for setup. **Not implemented yet!**
Command will be:
```shell
sudo ./setup_product. sh --git-email="f.last@ecotec-scantec.com" --sw-dir=/home/ai-blox/software/ --product=smartscan
```

## CompoScan Setup
Use the [`setup_product.sh`](./setup_product.sh) script for setup. **Implemented, but not thoroughly tested!**
Command will be:
```shell
sudo ./setup_product. sh --git-email="f.last@ecotec-scantec.com" --sw-dir=/home/ai-blox/software/ --product=composcan
```
