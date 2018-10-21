# checkpoint ansible
# ==================
# 
# Ansible Server w/ Check Point SDK
# 
# Requires ...
# 
# Build via "docker build -t [insert image name] ."
#
# Run via "run -ti -v local/dir/on/host:/container/mnt/location/ [insert image name]:latest

# Base image is ubuntu
FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    ansible \
    ssh \
    net-tools \
    curl \
    vim \
    openssh-server \
    sudo

#ENTRYPOINT [ "ansible" ]
#ENTRYPOINT [ "ansible-playbook" ]

RUN useradd -m dev && \
    adduser dev sudo && \
    echo "dev:dev" | chpasswd

# Init user dev
USER dev
WORKDIR /home/dev
ENV HOME /home/dev

# set up vimrc
RUN echo "syntax on" >> .vimrc && \
    echo "set number" >> .vimrc && \
    echo "filetype plugin indent on" >> .vimrc && \
    echo "set tabstop=4" >> .vimrc && \
    echo "set expandtab" >> .vimrc && \
    echo "set cursorline" >> .vimrc


EXPOSE 22

ENV NAME ansible
    
# Base command for environment
CMD ["/bin/bash"]

#ENTRYPOINT [ "ansible" ]
#ENTRYPOINT [ "ansible-playbook" ]
