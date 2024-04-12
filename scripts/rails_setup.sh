#!/bin/bash
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y ansible wget curl
ansible-playbook scripts/rails_setup.yml
bundle config set --local path '.local'
npm install npx
npm install yarn -g
bundle install



