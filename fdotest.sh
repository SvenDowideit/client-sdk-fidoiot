#!/bin/bash

set -xe

# requires docker, httpie, jq, uuidgen
# https://github.com/httpie/httpie

PORTAINER_URL=https://portainer.p1.alho.st
PORTAINER_NAME="p1"
USERNAME="admin"
PWD='59QxqYiE5yWJb064'
DEVICESERIALNUMBER=$(uuidgen | sed 's/-.*//')
MANUFACTURER=http://10.13.13.10:8039/
OWNER=http://10.13.13.10:8042/

echo "device serial number: ${DEVICESERIALNUMBER}"
docker volume create "fdo-device-${DEVICESERIALNUMBER}"

# Manfacturing stage
#docker pull ptrrd/client-sdk-fidoiot:linux-dind
docker run -it \
    --name fdo-device-${DEVICESERIALNUMBER} \
    --privileged \
    --net host \
    --env DEVICESERIALNUMBER=${DEVICESERIALNUMBER} \
    --env MANUFACTURER=${MANUFACTURER} \
    -v "fdo-device-${DEVICESERIALNUMBER}:/src/client-sdk-fidoiot/data/" \
        ptrrd/client-sdk-fidoiot:linux-dind

# get the voucher
curl -v --digest --user apiUser:05EV9CbHbAQANc1t \
    --output ${DEVICESERIALNUMBER}.bin \
    ${MANUFACTURER}api/v1/vouchers/${DEVICESERIALNUMBER}

# device registration stage
echo "portainer login"
#while [[ "$$(curl --insecure -s -o /dev/null -w ''%{http_code}'' https://manager1:9001/ping)" != "204" ]]; do sleep 1; done
jwt=`http --verify false --ignore-stdin ${PORTAINER_URL}/api/auth username="${USERNAME}" password="${PWD}" | jq .jwt | cut -d '"' -f 2`
echo "jwt = ${jwt}"

VOUCHERS=$(http --verify false --form --ignore-stdin GET ${PORTAINER_URL}/api/fdo/list "Authorization: ${jwt}")
echo "GetVouchers: ${VOUCHERS}"

echo "post voucher"
TMPFILE=$(mktemp)
http --verify false --verbose --debug \
    -d --output ${TMPFILE} \
    --form --ignore-stdin POST \
    ${PORTAINER_URL}/api/fdo/register \
    "Authorization: ${jwt}" \
    voucher@${DEVICESERIALNUMBER}.bin

SERVICEINFO=$(cat ${TMPFILE})
GUID=$(cat ${TMPFILE} | jq -r .guid )
rm ${TMPFILE}

echo "PutVouchers: ${SERVICEINFO}"

if [[ "${GUID}" == "" ]]; then
    echo "ERROR in posting voucher - no GUID"
    exit
fi


VOUCHERS=$(http --verify false --form --ignore-stdin GET ${PORTAINER_URL}/api/fdo/list "Authorization: ${jwt}")
# this list should container the device GUID 
echo "GetVouchers: ${VOUCHERS}"

EDGE_ENV_NAME=fdo-device-${DEVICESERIALNUMBER}

TMPFILE=$(mktemp)
http --verify false --verbose --debug \
    -d --output ${TMPFILE} \
    --form --ignore-stdin POST ${PORTAINER_URL}/api/endpoints "Authorization: ${jwt}" \
    Name=="${EDGE_ENV_NAME}" \
    EndpointCreationType:=4 \
    GroupID:=1 \
    TLS:=false \
    TLSSkipVerify:=true \
    TLSSkipClientVerify:=true \
    URL=="${PORTAINER_URL}"
CREATEENDPOINT=$(cat ${TMPFILE})
rm ${TMPFILE}
EDGE_KEY=$(echo ${CREATEENDPOINT} | jq -r '.EdgeKey')

CONFIGUREDEVICE=$(http --verify false --verbose --debug \
    --form --ignore-stdin POST \
    ${PORTAINER_URL}/api/fdo/configure/${GUID} \
    "Authorization: ${jwt}" \
    edgekey=="${EDGE_KEY}" \
    name=="${EDGE_ENV_NAME}" \
    profile=="docker-standalone-edge")

echo "Portainer says ${CONFIGUREDEVICE}"

# list the device's ServiceInfo
curl -v --digest -X GET --user apiUser:05EV9CbHbAQANc1t http://10.13.13.10:8042/api/v1/device/svi?guid=${GUID}


# if you can watch the fdo rz container logs, it'll eventually happen :D
echo
echo "running in container fdo-device-${DEVICESERIALNUMBER}"
echo
echo "Waiting for 60 seconds, check for Owner log to container to have 'TO0 Client finished for GUID ${GUID}' "
echo
sleep 60

echo to complete the FDO onboarding, please run:
echo
echo docker start -a fdo-device-${DEVICESERIALNUMBER}
echo
