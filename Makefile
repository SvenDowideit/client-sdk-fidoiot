

DEVICESERIALNUMBER:=$(shell uuidgen | sed 's/-.*//')
MANUFACTURER:=http://10.13.13.10:8039/


build:
	docker build -t ptrrd/client-sdk-fidoiot:linux-dind .

push:
	docker push ptrrd/client-sdk-fidoiot:linux-dind

shell:
	docker run --rm -it \
		--net host \
		--entrypoint bash \
		ptrrd/client-sdk-fidoiot:linux-dind bash


	#	-v $(PWD)/data/:/src/client-sdk-fidoiot/data/ \
