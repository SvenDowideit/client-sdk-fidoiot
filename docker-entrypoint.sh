#!/bin/bash

set -ex

FIRSTRUN="false"

MANUFACTURER=${MANUFACTURER:-http://localhost:8039/}
if [[ ! -e data/manufacturer_addr.bin ]]; then
    echo "Setting the Manufarturer URL to ${MANUFACTURER}"
    echo -n "${MANUFACTURER}" > data/manufacturer_addr.bin
    FIRSTRUN="true"
fi

DEVICESERIALNUMBER=${DEVICESERIALNUMBER:-generate}
if [[ ! -e data/manufacturer_sn.bin ]]; then
    echo "Setting the Device Serial number to ${DEVICESERIALNUMBER}"
    echo -n "${DEVICESERIALNUMBER}" > data/manufacturer_sn.bin
    FIRSTRUN="true"
fi

# generate the keys
if [[ ! -e ./data/ecdsa256privkey.pem ]]; then
    # TODO: don't re-run this if all the files are there
    utils/keys_gen.sh .
    FIRSTRUN="true"
fi


# need docker here during onboarding
if [ "$FIRSTRUN" != "true" ]; then
    nohup /usr/local/bin/startup.sh > docker.log &
    echo "wait for Docker to start"
    sleep 5
    DOCKER_HOST=unix:///run/user/1000/docker.sock
fi

build/linux-client


echo "Device Serial number: ${DEVICESERIALNUMBER}"

if [[ "$FIRSTRUN" != "true" ]]; then
    echo "waiting to be asked to exit"
    read
fi