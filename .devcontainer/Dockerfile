######################################
# Based on Ubuntu image
######################################
FROM ubuntu

LABEL maintainer="Benoit Verhaeghe"

######################################
# Update Ubuntu apt and install some tools
######################################
RUN  apt-get update \
  && apt-get install -y wget git unzip libpulse0 libasound2 libcairo2 


# Required for the readme moosebook
RUN  apt-get install -y openjdk-17-jdk openjdk-17-jre \
  && rm -rf /var/lib/apt/lists/*

######################################
# Have an own directory for the tool
######################################
RUN mkdir -p /root/pharo
WORKDIR /root/pharo

######################################
# Download Pharo using Zeroconf & start script
######################################
RUN mkdir /root/pharo/Moose64-12-PLS
WORKDIR /root/pharo/Moose64-12-PLS
RUN wget https://github.com/badetitou/Pharo-LanguageServer/releases/download/v5.0.0/Moose64-12-PLS.zip
RUN unzip Moose64-12-PLS.zip

WORKDIR /root/pharo/
RUN mkdir /root/pharo/pharo-vm
WORKDIR /root/pharo/pharo-vm
RUN wget https://files.pharo.org/get-files/120/pharo-vm-Linux-aarch64-latest.zip
RUN unzip pharo-vm-Linux-aarch64-latest.zip
