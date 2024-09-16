#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y ansible wget curl rsync git


# Install Ruby


export NVM_DIR="$HOME/.nvm"
echo 'export GEM_HOME=~/.ruby/' >> ~/.bashrc
echo 'export PATH="$PATH:~/.ruby/bin"' >> ~/.bashrc

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
. ~/.nvm/nvm.sh
nvm install 20
npm install yarn -g

source ~/.bashrc

export GEM_HOME=~/.ruby/
export PATH="$PATH:~/.ruby/bin"

GEM_HOME=~/.ruby/ PATH="$PATH:~/.ruby/bin" ansible-playbook scripts/rails_prod.yml
GEM_HOME=~/.ruby/ PATH="$PATH:~/.ruby/bin" gem install bundler

bundle config set --local path '.local'
GEM_HOME=~/.ruby/ PATH="$PATH:~/.ruby/bin" gem install rails
GEM_HOME=~/.ruby/ PATH="$PATH:~/.ruby/bin" bundle install




