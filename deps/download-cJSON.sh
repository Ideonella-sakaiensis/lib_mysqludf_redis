#!/bin/bash
VER=$1
URL="https://github.com/DaveGamble/cJSON/archive/v${VER}.tar.gz"
MODULE_NAME=cJSON
echo "Downloading $URL"
wget $URL -O /tmp/${MODULE_NAME}.tar.gz
tar zxvf /tmp/${MODULE_NAME}.tar.gz
rm -rf ${MODULE_NAME}
mv ${MODULE_NAME}-${VER} ${MODULE_NAME}
