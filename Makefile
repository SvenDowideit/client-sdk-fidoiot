
build:
	docker build -t ptrrd/client-sdk-fidoiot:linux .

push:
	docker push ptrrd/client-sdk-fidoiot:linux

run:
	docker run --rm -it \
		--net host \
			ptrrd/client-sdk-fidoiot:linux ./build/linux-client

shell:
	docker run --rm -it \
		--net host \
		ptrrd/client-sdk-fidoiot:linux bash


	#	-v $(PWD)/data/:/src/client-sdk-fidoiot/data/ \
