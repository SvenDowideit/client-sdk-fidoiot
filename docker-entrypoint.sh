#!/bin/bash

set -ex

MANUFACTURER=${MANUFACTURER:-http://localhost:8039/}
if [[ ! -e data/manufacturer_addr.bin ]]; then
    echo "Setting the Manufarturer URL to ${MANUFACTURER}"
    echo -n "${MANUFACTURER}" > data/manufacturer_addr.bin
fi

DEVICESERIALNUMBER=${DEVICESERIALNUMBER:-generate}
if [[ ! -e data/manufacturer_sn.bin ]]; then
    echo "Setting the Device Serial number to ${DEVICESERIALNUMBER}"
    echo -n "${DEVICESERIALNUMBER}" > data/manufacturer_sn.bin
fi

# generate the keys
if [[ ! -e ./data/ecdsa256privkey.pem ]]; then
    # TODO: don't re-run this if all the files are there
    utils/keys_gen.sh .
fi

build/linux-client


echo "Device Serial number: ${DEVICESERIALNUMBER}"
 