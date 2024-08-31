#!/bin/bash

# Copy skel files
if [ ! -f ~/.init_done ]; then
    echo "Copying skel files"
    cp -rT /etc/skel ~
    touch ~/.init_done
else
    echo "Skel files already copied"
fi

# volta install
if [ ! -f ~/.volta ]; then
    echo "Installing volta"
    curl https://get.volta.sh | bash
    echo "Volta installed"
else
    echo "Volta already installed"
fi

# start dockerd
echo "Starting dockerd"
sudo dockerd > /dev/null 2>&1 &

# start dockerd
echo "Starting dockerd"
sudo dockerd > /dev/null 2>&1 &

# create known_hosts and .ssh dir
if [ ! -f ~/.ssh/known_hosts ]; then
    echo "Creating known_hosts"
    if [ ! -d ~/.ssh ]; then
        echo "Creating .ssh dir"
        mkdir ~/.ssh
    else
        echo ".ssh dir already exists"
    fi
    touch ~/.ssh/known_hosts
else
    echo "known_hosts already exists"
fi

# Clone repo
echo "Cloning repo"
ssh-keyscan github.com >> ~/.ssh/known_hosts
if [ ! -d ~/yoiyami ]; then
    echo "Cloning repo"
    git clone "git@github.com:yoiyami-dev/yoiyami.git"
    echo "Cloned repo"
else
    echo "Repo already cloned"
fi
