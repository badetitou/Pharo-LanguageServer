######################################
# Based on Ubuntu image
######################################
FROM ubuntu

LABEL maintainer="Benoit Verhaeghe"

######################################
# Update Ubuntu apt and install some tools
######################################
RUN  apt-get update \
  && apt-get install -y wget \
  && apt-get install -y git \
  && apt-get install -y unzip \
  && apt-get install -y libpulse0 \
  && apt-get install -y libasound2 \
  && rm -rf /var/lib/apt/lists/*

######################################
# Have an own directory for the tool
######################################
RUN mkdir -p /root/pharo
WORKDIR /root/pharo

######################################
# Download Pharo using Zeroconf & start script
######################################
RUN mkdir /root/pharo/Moose64-10-PLS
WORKDIR /root/pharo/Moose64-10-PLS
RUN wget https://github.com/badetitou/Pharo-LanguageServer/releases/download/v3.1.1/Moose64-10-PLS.zip
RUN unzip Moose64-10-PLS.zip

WORKDIR /root/pharo/
RUN mkdir /root/pharo/pharo-vm
WORKDIR /root/pharo/pharo-vm
RUN wget https://files.pharo.org/get-files/90/pharo64-linux-headless-latest.zip
RUN unzip pharo64-linux-headless-latest.zip 
