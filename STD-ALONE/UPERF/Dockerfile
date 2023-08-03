FROM quay.io/centos/centos:stream9
RUN dnf update -y
RUN dnf -y install epel-release
RUN dnf install -y procps-ng htop vim python3 pciutils iproute net-tools ethtool tcpdump
COPY src/uperf /usr/bin
COPY workloads /usr/workloads

