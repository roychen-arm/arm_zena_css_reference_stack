FROM ubuntu:22.04

RUN apt-get update
RUN apt-get install -y apt-utils
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
    iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev telnet \
    xterm python3-subunit mesa-common-dev file libacl1 liblz4-tool locales zstd \
    tmux python3-newt iproute2 python3-kconfiglib
RUN apt-get install -y sudo vim locales
RUN locale-gen en_US.UTF-8 && update-locale
RUN pip3 install kas

RUN groupadd -g 1001 docker
RUN useradd -m -r -u 1001 -g 1001 -s /bin/bash docker && adduser docker sudo && echo "docker:docker" | chpasswd

USER docker

RUN mkdir ~/arm-auto-solutions
WORKDIR /home/docker/arm-auto-solutions

COPY ./run_fvp.sh /home/docker/arm-auto-solutions
RUN pip3 install -U pip
RUN pip3 install --upgrade kas==4.8.1

RUN git clone https://git.gitlab.arm.com/automotive-and-industrial/arm-auto-solutions/sw-ref-stack.git --branch v2.1

CMD /sbin/init
