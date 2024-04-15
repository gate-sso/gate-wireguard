#!/bin/bash
ansible-playbook scripts/wireguard.yml 
sudo groupadd wg_conf
sudo usermod -aG wg_conf `whoami`
sudo chown root.wg_conf /etc/wireguard/wg0.conf
sudo chmod 664 /etc/wireguard/wg0.conf