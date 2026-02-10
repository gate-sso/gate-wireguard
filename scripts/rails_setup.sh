export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y ansible wget curl

export NVM_DIR="$HOME/.nvm"

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
. ~/.nvm/nvm.sh
nvm install 20
export CI=true
corepack enable



#need to source appropriate shell rc file
if [ -n "$BASH_VERSION" ]; then
    echo 'export GEM_HOME=~/.ruby/' >> ~/.bashrc
    echo 'export PATH="$PATH:~/.ruby/bin"' >> ~/.bashrc
    source ~/.bashrc
elif [ -n "$ZSH_VERSION" ]; then
    echo 'export GEM_HOME=~/.ruby/' >> ~/.zshrc
    echo 'export PATH="$PATH:~/.ruby/bin"' >> ~/.zshrc
    source ~/.zshrc
fi

#if Object object error happens
npm i -d postcss  
yarn install

ansible-playbook scripts/rails_setup.yml
gem install bundler
bundle config set --local path '.local'
gem install rails

bundle install

