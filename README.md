# Gate-WireGuard

## Wireguard Web UI with Google Single Sign on for wireguard management

Gate-WireGuard is self sign up oauth enabled VPN server providing WireGuard as backend for client connections. it's Web-UI and configuration management
tool for wireguard server. It automatically reloads the configuration when new devices are added, and also provides a way to manage the devices.

# Production Deployment

Deploy to a fresh Ubuntu 22.04/24.04 server from your local machine using Ansible.

**Prerequisites:** Ansible installed locally (`brew install ansible` or `pip install ansible`), root SSH access to the server.

```bash
# First install (prompts for domain, OAuth credentials, etc.)
./deploy/install_gate.sh vpn.example.com

# Update app code only (git pull + bundle + assets + migrate + restart)
./deploy/install_gate.sh vpn.example.com --tags update

# Re-configure settings
./deploy/install_gate.sh vpn.example.com --configure

# Fix SSL after DNS propagation
./deploy/install_gate.sh vpn.example.com --tags ssl

# Preview changes without applying
./deploy/install_gate.sh vpn.example.com --diff --check
```

**What gets installed:** Ruby 3.3.4 (rbenv), Node 20, MySQL, Redis, Nginx, WireGuard, Let's Encrypt SSL, systemd services for Puma and WireGuard config watcher.

**After deploy:** Sign in via Google OAuth, configure WireGuard network settings in the admin panel, then add VPN devices.

Server config (with secrets) is stored in `deploy/servers/<host>.yml` (gitignored).

---

# Development Setup

1. Checkout gate-wireguard and run the setup script:

```bash
scripts/rails_setup.sh
```

if you need to setup docker as well, because we need compose plugin, please use following script to setup docker.

```bash
sh scripts/docker_setup.sh
```

2. Docker in only required if you do not want to install mysql on local server, else you can just install mysql server
   - to run docker, just run `docker compose up db -d` and you are good to go
3. Setup gate_wireguard_dev database in mysql for non-root users, for dev you can use root user as well.
   |

   ```sql
   create database gate_wireguard_dev;
   grant all privileges on gate_wireguard_dev to 'gate_wireguard'@% idenfied by 'gate_wireguard';
   create database gate_wireguard_test;
   grant all privileges on gate_wireguard_test to 'gate_wireguard'@% identified by 'gate_wireguard';
   ```

4. Run `rails db:create db:migrate` to create the database and run the migrations
5. If you rather want to use root user root@localhost just do the following.

   ```sudo mysql -u root -p
   ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
       FLUSH PRIVILEGES;
   ```

6. Setup RubyLSP and watchman and then execute

```shell
bundle exec srb typecheck --lsp
```

---

### Stack

- Ruby 3.3.4, Rails 8.0.2, MySQL, Redis
- Bootstrap 5.3.3, Stimulus.js, Hotwire Turbo
- Node 20, Yarn 4

### Useful commands

If you are doing local development and you need to sync the file to remote box as they change, following command can be useful for running rails server that automatically gets new files

```shell
watchmedo shell-command \
    --recursive \
    --command='echo "${watch_src_path}"' \
    /some/folder
```

If you running Ubuntu and have "ruby-full" package, and want to install gems locally, following commands are useful

```shell
echo 'export GEM_HOME=~/.ruby/' >> ~/.bashrc
echo 'export PATH="$PATH:~/.ruby/bin"' >> ~/.bashrc
source ~/.bashrc
```

You may end up getting application.css not found error. in that case please install yarn

```shell
npm install yarn
#or
npm install --global yarn
yarn add sass
yarn build:css
```

This is a know problem with Yarn, Bootstrap and Rails 7 combo.

If you want to install newer node framework, required for this repo

```shell
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
. ~/.nvm/nvm.sh
nvm install 20
```

If you are not able to get ruby to build and compile, use rvm on macos and then

```bash
brew install ruby-build
brew install openssl@1.1
export PKG_CONFIG_PATH=/usr/local/opt/openssl@1.1/lib/pkgconfig/
rvm install 3.0.2 --with-openssl-dir=/usr/local/opt/openssl@1.1
#for rbenv
RUBY_CONFIGURE_OPTS=--with-openssl-dir=/usr/local/opt/openssl@1.1
rbenv install 3.0.2
```

On Mac installing Ruby

```
rvm install ruby-3.3.4 --reconfigure --enable-yjit --with-openssl-dir=$(brew --prefix openssl@3.0)
```

Also, please read brew's post install messages to be able to install ruby 3.0.2 successfully

Getting wireguard to work inside lxc containers you need to use [proxy device](https://linuxcontainers.org/incus/docs/main/reference/devices_proxy/)W

```bash
incus config device add gate <udp51820> proxy listen=udp:0.0.0.0:51820 connect=udp:0.0.0.0:51820
incus config device add gate tcp8080 proxy listen=tcp:0.0.0.0:8080 connect=tcp:0.0.0.0:8080

```

Also, once you have wireguard setup, you need to be able to accept the traffic, and source nat it.

```bash
sudo iptables -A FORWARD -i wg0 -o eth0 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source <the lan interface>
sudo iptables -t nat -A POSTROUTING -o eth0@if16 -j SNAT --to-source <the lan/vpc interface>
```

We use snat because we are using a private ip address, and we need to masquerade it to the routable return address for the server.

So our traffic works like this, here is ascii diagram for VPN Client -> VPN Server -> Local Network

```
+-----------------+        +-----------------+        +-----------------+
|                 |        |                 |        |                 |
|  VPN Client     |------->|  VPN Server     |------->|  Local Network  |
|                 |        |                 |        |                 |
+-----------------+        +-----------------+        +-----------------+
        VPN Traffic       wg0    VPN Traffic  eth0       Local Traffic
```

so in this case SNAT address will be the eth0 address of the VPN Server, and the return traffic will be sent to the VPN Server, which will then forward it to the VPN Client.

#### Credits

OpenSource is not possible without people contributing to it, The following posts, resources have helped me immensely to get this going off the ground. Some credits to internet reading material for helping me with various tasks

- Ryan Bigg - [Adding bootstrap to rails](https://ryanbigg.com/2023/04/rails-7-bootstrap-css-javascript-with-esbuild)
