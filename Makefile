

DEVICESERIALNUMBER:=$(shell uuidgen | sed 's/-.*//')
MANUFACTURER:=http://10.13.13.10:8039/


build:
	docker build -t ptrrd/client-sdk-fidoiot:linux .

push:
	docker push ptrrd/client-sdk-fidoiot:linux

run:
	echo "device serial number: $(DEVICESERIALNUMBER)"
	docker volume create "fdo-device-$(DEVICESERIALNUMBER)"

	# Manfacturing stage
	docker run --rm -it \
		--net host \
		--env DEVICESERIALNUMBER=$(DEVICESERIALNUMBER) \
		--env MANUFACTURER=$(MANUFACTURER) \
		-v "fdo-device-$(DEVICESERIALNUMBER):/src/client-sdk-fidoiot/data/" \
			ptrrd/client-sdk-fidoiot:linux

	# get the voucher
	curl -v --digest --user apiUser:05EV9CbHbAQANc1t \
		--output $(DEVICESERIALNUMBER).bin \
		$(MANUFACTURER)api/v1/vouchers/$(DEVICESERIALNUMBER)

shell:
	docker run --rm -it \
		--net host \
		--entrypoint bash \
		ptrrd/client-sdk-fidoiot:linux bash


	#	-v $(PWD)/data/:/src/client-sdk-fidoiot/data/ \
