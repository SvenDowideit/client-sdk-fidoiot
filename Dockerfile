# see https://github.com/secure-device-onboard/client-sdk-fidoiot/blob/master/docs/linux.md

FROM ubuntu:20.04

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq python-setuptools clang-format dos2unix ruby \
  libglib2.0-dev libpcap-dev autoconf libtool libproxy-dev libmozjs-52-0 doxygen cmake libssl-dev mercurial \
  make gcc
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq wget

WORKDIR /src/

# Steps to Upgrade the OpenSSL* Toolkit to Version 1.1.1k
RUN wget https://www.openssl.org/source/openssl-1.1.1k.tar.gz
RUN tar -zxf openssl-1.1.1k.tar.gz
WORKDIR /src/openssl-1.1.1k/
RUN ./config
RUN make
RUN make test
RUN mv /usr/bin/openssl /usr/bin/openssl.BACKUP
RUN make install
RUN ln -s /usr/local/bin/openssl /usr/bin/openssl
RUN ldconfig
RUN openssl version

RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq git
WORKDIR /src/
RUN git clone --depth 1 -b v1.0.0 https://github.com/intel/safestringlib
WORKDIR /src/safestringlib/
RUN mkdir obj && make
ENV SAFESTRING_ROOT=/src/safestringlib

WORKDIR /src/
RUN git clone --depth 1 -b v0.5.3 https://github.com/intel/tinycbor
WORKDIR /src/tinycbor/
RUN make
ENV TINYCBOR_ROOT=/src/tinycbor

RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq build-essential
WORKDIR /src/client-sdk-fidoiot/
COPY . /src/client-sdk-fidoiot/
#RUN make pristine
RUN cmake -DREUSE=true
RUN make
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq xxd

# from https://github.com/secure-device-onboard/client-sdk-fidoiot/blob/master/docs/setup.md#3-setting-the-manufacturer-network-address
# YES, it needs the :port
# This is the Device Initialization (DI) protocol:
ENV MANUFACTURER="http://localhost:8039/"
# get rid of the defaults so the entrypoint sets it
RUN rm data/manufacturer_addr.bin

ENTRYPOINT "./docker-entrypoint.sh"