#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y ansible wget curl rsync git libssl-dev libreadline-dev zlib1g-dev libffi-dev libffi8

if command -v ruby >/dev/null 2>&1; then
  INSTALLED_RUBY_VERSION=$(ruby -v | awk '{print $2}')
  echo "Ruby is installed. Version: $INSTALLED_RUBY_VERSION"

else
  echo "Ruby is not installed. Proceeding with installation."

  cd ~
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  sudo rm -rf ruby-3.3.4.tar ruby-3.3.4
  wget "https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.4.tar.gz"
  tar -xzvf ruby-3.3.4.tar.gz
  cd ruby-3.3.4
  ./configure --disable-install-rdoc --enable-yjit --with-libffi-dir=/usr/lib/x86_64-linux-gnu
  make
  sudo make install
fi


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

cd gate-wireguard

GEM_HOME=~/.ruby/ PATH="$PATH:~/.ruby/bin" ansible-playbook scripts/rails_prod.yml
GEM_HOME=~/.ruby/ PATH="$PATH:~/.ruby/bin" gem install bundler