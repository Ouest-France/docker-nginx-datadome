FROM debian:stretch
ARG DATADOME_VERSION="1.16.1-2.36~94"
WORKDIR /tmp
RUN apt update && apt install wget gnupg2 -y
RUN echo 'deb http://download.opensuse.org/repositories/isv:/datadome/Debian_9.0/ /' > /etc/apt/sources.list.d/isv:datadome.list && \
wget -nv https://download.opensuse.org/repositories/isv:datadome/Debian_9.0/Release.key -O Release.key && \
apt-key add - < Release.key && \
apt-get update && \
apt-get install nginx-datadome=${DATADOME_VERSION} -y
