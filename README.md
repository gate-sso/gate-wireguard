## Gate-WireGuard

Gate-WireGuard is self sign up oauth enabled VPN server providing WireGuard as backend for client connections. it's Web-UI and configuration management 
tool for wireguard server. It automatically reloads the configuration when new devices are added, and also provides a way to manage the devices.

#### Installation

##### Source Code
* Checkout the latest source code, and run scripts/rails_prod.sh
* Add changes the config/database.yml to point to your mysql server

##### Google Auth
* Go to Google cloud console, and create a new project, and enable oAuth for this project, make note of client id and secret.
* Create .env file in the root of the project, and add the following
```shell
GOOGLE_CLIENT_ID=<client_id>
GOOGLE_CLIENT_SECRET=<client_secret>
GOOGLE_HOSTED_DOMAINS=<your_domain>
```

##### Networking, Server setup
* Just setup caddy to point to gate-wireguard server. Simple caddy file can be like this
````shell
gate.<your domain name> {
  reverse_proxy 127.0.0.1:8080
}
````
* Configure wg-service. Checkout wireguard-conf-watcher.service file for more details.
* You will need to enable port 51820 on your firewall, and forward it to the server running gate-wireguard
* Wireguard will need traffic routing and snat as well You can use the following iptables rules to get it working
```shell
sudo iptables -A FORWARD -i wg0 -o eth0 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source <the lan interface>
sudo iptables -t nat -A POSTROUTING -o eth0@if16 -j SNAT --to-source <the lan/vpc interface>
```

##### WireGuard
* goto gate.<yourdomain> and sign in using allowed domain name, check default configuration, add your public end point, private ip address, click "Save & Generate configuration"
* Add your local network address, beware if you enter 0.0.0.0 it will route all traffic through vpn and you will need to setup a DNS server as well.
* Then click <Gate> and add your device, download the configuration file, and use it to connect to the VPN server.
* Standard wireguard clients work with this setup, you can use wireguard on linux, windows, macos, ios, android etc. Please [click here](https://www.wireguard.com/install/) for more information on clients

General traffic setup should look like this, here is ascii diagram for VPN Client -> VPN Server -> Local Network

```
+-----------------+        +-----------------+        +-----------------+
|                 |        |                 |        |                 |
|  VPN Client     |------->|  VPN Server     |------->|  Local Network  |
|                 |        |                 |        |                 |
+-----------------+        +-----------------+        +-----------------+
        VPN Traffic       wg0    VPN Traffic  eth0       Local Traffic
```


## Development

1. Checkout gate-wireguard, and run the following commands to get it running

````bash
scripts/rails_setup.sh
````
2. Docker in only required if you do not want to install mysql on local server, else you can just install mysql server
   * to run docker, just run ```docker compose up db -d``` and you are good to go
3. Setup gate_wireguard_dev database in mysql for non-root users, for dev you can use root user as well.
    |
    ```sql
   create database gate_wireguard_dev;
   grant all privileges on gate_wireguard_dev to 'gate_wireguard'@% idenfied by 'gate_wireguard';
   create database gate_wireguard_test;
   grant all privileges on gate_wireguard_test to 'gate_wireguard'@% identified by 'gate_wireguard';
    ```
4. Run ```rails db:create db:migrate``` to create the database and run the migrations
5. If you rather want to use root user root@localhost just do the following.
    ```sudo mysql -u root -p
   ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
        FLUSH PRIVILEGES;
    ```

---
#### Deployment Summary
* Ruby version - 3.0.2p107
* System dependencies
  * mysql header
  * nodejs
  * install gems - rails and bundler

* Configuration
  * database configuration

* Database creation
  * mysql command as given above

* Database initialization
  * rails db:create db:migrate

* How to run the test suite
  * rspec

* Services (job queues, cache servers, search engines, etc.)
  * docker-compose up

* Deployment instructions - You can setup gate-wireguard with or without docker, with docker, it's just docker-compose, without docker, please follow the steps below
  * checkout latest tar, run ./setup_production.sh
  * run ./configure_production.sh (this will create database etc)


#### Useful commands

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

If you want to install newer node framework, required for this repo

```shell
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
. ~/.nvm/nvm.sh
nvm install 20
```

If you are not able to get ruby to build and compile, use rvm on macos and then
    
```shell
brew install ruby-build
brew install openssl@1.1
export PKG_CONFIG_PATH=/usr/local/opt/openssl@1.1/lib/pkgconfig/
rvm install 3.0.2 --with-openssl-dir=/usr/local/opt/openssl@1.1
```

Getting wireguard to work inside lxc containers you need to use [proxy device](https://linuxcontainers.org/incus/docs/main/reference/devices_proxy/)W

```shell
incus config device add gate <udp51820> proxy listen=udp:0.0.0.0:51820 connect=udp:0.0.0.0:51820
incus config device add gate tcp8080 proxy listen=tcp:0.0.0.0:8080 connect=tcp:0.0.0.0:8080

```
    
Also, once you have wireguard setup, you need to be able to accept the traffic, and source nat it.

```shell
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

* Ryan Bigg - [Adding bootstrap to rails](https://ryanbigg.com/2023/04/rails-7-bootstrap-css-javascript-with-esbuild) 

