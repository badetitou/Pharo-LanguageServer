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
RUN mkdir -p /tmp/pharo
WORKDIR /tmp/pharo

######################################
# Download Pharo using Zeroconf & start script
######################################
RUN mkdir Pharo64-10-PLS
WORKDIR /tmp/pharo/Pharo64-10-PLS
RUN wget https://github.com/badetitou/Pharo-LanguageServer/releases/download/v3.0.1/Pharo64-10-PLS.zip
RUN unzip Pharo64-10-PLS.zip

WORKDIR /tmp/pharo/
RUN mkdir pharo64-linux-headless-latest
WORKDIR /tmp/pharo/pharo64-linux-headless-latest
RUN wget https://files.pharo.org/get-files/90/pharo64-linux-headless-latest.zip
RUN unzip pharo64-linux-headless-latest.zip 
