## Gate-WireGuard

Gate-WireGuard is self sign up oauth enabled VPN server providing WireGuard as backend for client connections.

* You will need to configure an oAuth backend, usually Google. We prefer Google because then you can limit your company domain to sign uop.
* Install Gate-WireGuard on a VM or Container
* WireGuard needs UDP port 51820 open, you can configure this on your router/firewall

## Setup

We configure the system using ansible. 

````bash
sudo apt-get install ansible wget curl 
wget <gate-sso> latest 
tar -czvf /path/to/gate-wireguard-latest.tar.gz 
cd gate-wireguard
````
execute following command if you want to do docker setup.
````bash
sudo ./setup.sh docker
````
execute following command if you want to do no docker setup. you will need to install mysql-server
````shell
sudo ./setup.sh docker
````

## Development

GateWireGuard is rails project, requires rails.
1. Install required libraries 
   |
    ```sudo apt-get install libmysqlclient-dev mysql-client git wget nodejs ruby-full docker.io```
2. Docker in only required if you do not want to install mysql on local server, else you can just install mysql server
3. Setup gate_wireguard_dev database in mysql
    |
    ```sql
   create database gate_wireguard_dev;
   grant all privileges on gate_wireguard_dev to 'gate_wireguard'@% idenfied by 'gate_wireguard';
   create database gate_wireguard_test;
   grant all privileges on gate_wireguard_test to 'gate_wireguard'@% identified by 'gate_wireguard';
    ```
4. Run database migrations and you should be good to go.


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
