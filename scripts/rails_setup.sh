#!/bin/bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y ansible wget curl
ansible-playbook scripts/rails_setup.yml
sudo gem install bundler
sudo gem install rails
bundle config set --local path '.local'
sudo npm install --save-exact --save-dev esbuild yarn npx -g
bundle install
bin/rails javascript:install:esbuild
yarn build
esbuild app/javascript/*.* --bundle --sourcemap --outdir=app/assets/builds --public-path=assets
sudo usermod -aG docker `whoami`
newgrp docker
#Monospace Neon, Monaco, 'Courier New', monospace


