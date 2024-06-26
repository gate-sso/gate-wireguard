export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y ansible wget curl

export NVM_DIR="$HOME/.nvm"
echo 'export GEM_HOME=~/.ruby/' >> ~/.bashrc
echo 'export PATH="$PATH:~/.ruby/bin"' >> ~/.bashrc
echo 'export GEM_HOME=~/.ruby/' >> ~/.zshrc
echo 'export PATH="$PATH:~/.ruby/bin"' >> ~/.zshrc

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
. ~/.nvm/nvm.sh
nvm install 20
npm install -g yarn

#need to source appropriate shell rc file
if [ -n "$BASH_VERSION" ]; then
    source ~/.bashrc
elif [ -n "$ZSH_VERSION" ]; then
    source ~/.zshrc
fi

ansible-playbook scripts/rails_setup.yml
gem install bundler
bundle config set --local path '.local'
gem install rails

bundle install