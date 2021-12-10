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

# add more fdo_sys resources
# see https://github.com/secure-device-onboard/pri-fidoiot/blob/2bac84514d02c89583585d3dfaa305681625c82a/component-samples/demo/owner/README.md
# https://secure-device-onboard.github.io/docs/0.5.0/fdo/fdo-serviceinfo-sys/
#curl -v --digest -X PUT --user apiUser:05EV9CbHbAQANc1t -H "Content-Type: application/octet-stream" --data 1 'http://10.13.13.10:8042/api/v1/device/svi?module=fdo_sys&var=active&priority=12&guid='${GUID}
#curl -v --digest -X PUT --user apiUser:05EV9CbHbAQANc1t -H "Content-Type: application/octet-stream" --data "touch /sven" 'http://10.13.13.10:8042/api/v1/device/svi?module=fdo_sys&var=exec&priority=12&guid='${GUID}
#curl -v --digest -X PUT --user apiUser:05EV9CbHbAQANc1t -H "Content-Type: application/octet-stream" --data "touch /sven" 'http://10.13.13.10:8042/api/v1/device/svi?module=fdo_sys&var=exec&priority=12&device=alldevice&os=allos&arch=X86_64&hash=allhash&guid='${GUID}
#curl -v --digest -X PUT --user apiUser:05EV9CbHbAQANc1t -H "Content-Type: application/octet-stream" --data "true" 'http://10.13.13.10:8042/api/v1/device/svi?module=fdo_sys&var=active&priority=12&device=alldevice&os=allos&arch=X86_64&hash=allhash&guid='${GUID}

#curl -v --digest -X PUT --user apiUser:05EV9CbHbAQANc1t -H "Content-Type: application/octet-stream" --data "touch /sven" 'http://10.13.13.10:8042/api/v1/device/svi?module=fdo_sys&var=exec&priority=12&arch=X86_64&hash=allhash&guid='${GUID}

#curl -v --digest -X PUT --user apiUser:05EV9CbHbAQANc1t -H "Content-Type: application/octet-stream" --data "touch /sven2" 'http://10.13.13.10:8042/api/v1/device/svi?module=fdo_sys&var=exec&priority=12&device=Intel-FDO-Linux&arch=x86&os=Linux&version=Ubuntu-14&hash=allhash&guid='${GUID}

# from https://github.com/secure-device-onboard/test-fidoiot/blob/6bdf0772a659ee997d4ee212f47ca65afc1af0b2/priTests/src/test/java/org/fidoalliance.fdo/test/PriSmokeTest.java
# use priority to ensure they get sent to the device in the right order.
# enable fdo_sys
# curl -v --digest -X PUT --user apiUser:05EV9CbHbAQANc1t \
#     -H "Content-Type: application/octet-stream" \
#     "${OWNER}api/v1/device/svi?module=fdo_sys&var=active&bytes=F5&priority=0&guid=${GUID}"
# # send the file
# curl -v --digest -X PUT --user apiUser:05EV9CbHbAQANc1t \
#     -H "Content-Type: application/octet-stream" --data-binary '@sven.sh' \
#     "${OWNER}api/v1/device/svi?module=fdo_sys&var=filedesc&priority=1&filename=init-${DEVICESERIALNUMBER}.sh&guid=${GUID}"
# run the file (this needs to be in cbor...)
#curl -v --digest -X PUT --user apiUser:05EV9CbHbAQANc1t \
#    -H "Content-Type: application/octet-stream" --data-binary '@sven.sh' \
#    "${OWNER}api/v1/device/svi?module=fdo_sys&var=exec&priority=2&filename=init-${DEVICESERIALNUMBER}.sh&guid=${GUID}"

# curl -v --digest -X PUT --user apiUser:05EV9CbHbAQANc1t \
#     -H "Content-Type: application/octet-stream" --data-binary '@sven.sh' \
#     'http://10.13.13.10:8042/api/v1/device/svi?module=fdo_sys&var=filedesc&priority=1&filename=init-${DEVICESERIALNUMBER}.sh&guid='${GUID}

# curl --location --digest -u apiUser:" + ownerApiPass + " "
#               + "--request PUT 'http://localhost:8042/api/v1/device/svi?module=fdo_sys&"
#               + "var=filedesc&priority=1&filename=linux64.sh&guid=" + guid
#               + "' --header 'Content-Type: application/octet-stream' --data-binary "
#               + "'@common/src/main/resources/linux64.sh'

CONFIGUREDEVICE=$(http --verify false --verbose --debug \
    --form --ignore-stdin POST \
    ${PORTAINER_URL}/api/fdo/configure/${GUID} \
    "Authorization: ${jwt}" \
    guid=${GUID} \
    device_name=${DEVICESERIALNUMBER} \
    device_profile="docker-standalone-edge")

echo "Portainer says ${CONFIGUREDEVICE}"

# list the device's ServiceInfo
curl -v --digest -X GET --user apiUser:05EV9CbHbAQANc1t http://10.13.13.10:8042/api/v1/device/svi?guid=${GUID}


# if you can watch the fdo rz container logs, it'll eventually happen :D
echo
echo "Waiting for 60 seconds, for Manufacturer to tell RZ about 'TO0 completed for GUID: ${GUID}' "
echo
sleep 60

echo to complete the FDO onboarding, please run:
echo
echo docker start -a fdo-device-${DEVICESERIALNUMBER}
echo
