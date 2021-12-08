#!/bin/bash

set -xe

# requires docker, httpie, jq, uuidgen
# https://github.com/httpie/httpie

PORTAINER_URL=https://portainer.p1.alho.st
PORTAINER_NAME="p1"
USERNAME="admin"
PWD='59QxqYiE5yWJb064'
DEVICESERIALNUMBER=$(uuidgen | sed 's/-.*//')
MANUFACTURER=http://localhst:8039/

echo "device serial number: ${DEVICESERIALNUMBER}"
docker volume create "fdo-device-${DEVICESERIALNUMBER}"

# Manfacturing stage
#docker pull ptrrd/client-sdk-fidoiot:linux
docker run -it \
    --name fdo-device-${DEVICESERIALNUMBER} \
    --net host \
    --env DEVICESERIALNUMBER=${DEVICESERIALNUMBER} \
    --env MANUFACTURER=${MANUFACTURER} \
    -v "fdo-device-${DEVICESERIALNUMBER}:/src/client-sdk-fidoiot/data/" \
        ptrrd/client-sdk-fidoiot:linux

# get the voucher
curl -v --digest --user apiUser:05EV9CbHbAQANc1t \
    --output ${DEVICESERIALNUMBER}.bin \
    ${MANUFACTURER}api/v1/vouchers/${DEVICESERIALNUMBER}

# device registration stage
echo "portainer login"
#while [[ "$$(curl --insecure -s -o /dev/null -w ''%{http_code}'' https://manager1:9001/ping)" != "204" ]]; do sleep 1; done
jwt=`http --verify false --ignore-stdin ${PORTAINER_URL}/api/auth username="${USERNAME}" password="${PWD}" | jq .jwt | cut -d '"' -f 2`
echo "jwt = ${jwt}"

VOUCHERS=$(http --verify false --form --ignore-stdin GET ${PORTAINER_URL}/api/hosts/fdo/list "Authorization: ${jwt}")
echo "GetVouchers: ${VOUCHERS}"

echo "post voucher"
TMPFILE=$(mktemp)
http --verify false --verbose --debug \
    -d --output ${TMPFILE} \
    --form --ignore-stdin POST \
    ${PORTAINER_URL}/api/hosts/fdo/register \
    "Authorization: ${jwt}" \
    voucher@${DEVICESERIALNUMBER}.bin

SERVICEINFO=$(cat ${TMPFILE})
GUID=$(cat ${TMPFILE} | sed 's/.*guid = //' | sed 's/\\n.*//')
rm ${TMPFILE}

echo "PutVouchers: ${SERVICEINFO}"

VOUCHERS=$(http --verify false --form --ignore-stdin GET ${PORTAINER_URL}/api/hosts/fdo/list "Authorization: ${jwt}")
# this list should container the device GUID 
echo "GetVouchers: ${VOUCHERS}"

# if you can watch the fdo rz container logs, it'll eventually happen :D
echo
echo "Waiting for 60 seconds, for Manufacturer to tell RZ about 'TO0 completed for GUID: ${GUID}' "
echo
sleep 60

echo to complete the FDO onboarding, please run:
echo
echo docker start -a fdo-device-${DEVICESERIALNUMBER}
echo
