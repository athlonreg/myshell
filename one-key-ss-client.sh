#!/bin/bash

prepare(){
	echo -e "\033[42;31m Install deps ... \033[0m"
	yum -y install epel-release
	yum -y install python-pip
	pip install shadowsocks
}

ss_conf(){
	echo -e "\033[42;31m Setup shadowsocks ... \033[0m"
	mkdir /etc/shadowsocks
	touch /etc/shadowsocks/shadowsocks.json

	server=localhost
	server_port=8443

	read -p "Input the shadowsocks server you want to setup(default is localhost): " server
	read -p "Input the shadowsocks server port you want to setup(default is 8443): " server_port
	read -p "Input the shadowsocks password you want to setup(default is 123456): " password
	read -p "Input the shadowsocks method you want to setup(default is aes-256-cfb): " method

	echo -e "{" > /etc/shadowsocks/shadowsocks.json
	echo -e "\t\"server\":\"$server\"," >> /etc/shadowsocks/shadowsocks.json
	echo -e "\t\"server_port\":$server_port," >> /etc/shadowsocks/shadowsocks.json
	echo -e '"\tlocal_address": "127.0.0.1",' >> /etc/shadowsocks/shadowsocks.json
	echo -e '"\tlocal_port":1080,' >> /etc/shadowsocks/shadowsocks.json
	echo -e "\t\"password\":\"$password\"," >> /etc/shadowsocks/shadowsocks.json
	echo -e '"\ttimeout":300, '>> /etc/shadowsocks/shadowsocks.json
	echo -e "\t\"method\":\"$method\"," >> /etc/shadowsocks/shadowsocks.json
	echo -e '"\tfast_open": false,' >> /etc/shadowsocks/shadowsocks.json
	echo -e '"\tworkers": 1' >> /etc/shadowsocks/shadowsocks.json
	echo -e "}" >> /etc/shadowsocks/shadowsocks.json
}

ss_service(){
	echo -e "\033[42;31m Setup shadowsocks services ... \033[0m"
	touch /etc/systemd/system/shadowsocks.service
	echo '[Unit]' >> /etc/systemd/system/shadowsocks.service
	echo 'Description=Shadowsocks' >> /etc/systemd/system/shadowsocks.service
	echo '[Service]' >> /etc/systemd/system/shadowsocks.service
	echo 'TimeoutStartSec=0' >> /etc/systemd/system/shadowsocks.service
	echo 'ExecStart=/usr/bin/sslocal -c /etc/shadowsocks/shadowsocks.json' >> /etc/systemd/system/shadowsocks.service
	echo '[Install]' >> /etc/systemd/system/shadowsocks.service
	echo 'WantedBy=multi-user.target' >> /etc/systemd/system/shadowsocks.service

	echo -e "\033[42;31m Boot shadowsocks services ... \033[0m"
	systemctl enable shadowsocks.service
	systemctl start shadowsocks.service
	systemctl status shadowsocks.service
}

ss_test(){
	echo -e "\033[42;31m Test shadowsocks connect ... \033[0m"
	curl --socks5 127.0.0.1:1080 http://httpbin.org/ip
}

privoxy_conf(){
	echo -e "\033[42;31m Boot privoxy ... \033[0m"
	yum install privoxy -y
	systemctl enable privoxy
	systemctl start privoxy
	systemctl status privoxy
	
	echo -e "\033[42;31m Setup privoxy ... \033[0m"
	echo 'listen-address 127.0.0.1:8118' >> /etc/privoxy/config
	echo 'forward-socks5t / 127.0.0.1:1080 .' >> /etc/privoxy/config
}

proxy_conf(){
	echo -e "\033[42;31m Setup proxy ... \033[0m"
	echo 'PROXY_HOST=127.0.0.1' >> /etc/profile
	echo 'export all_proxy=http://$PROXY_HOST:8118' >> /etc/profile
	echo 'export ftp_proxy=http://$PROXY_HOST:8118' >> /etc/profile
	echo 'export http_proxy=http://$PROXY_HOST:8118' >> /etc/profile
	echo 'export https_proxy=http://$PROXY_HOST:8118' >> /etc/profile
	echo 'export no_proxy=localhost,172.16.0.0/16,192.168.0.0/16.,127.0.0.1,10.10.0.0/16' >> /etc/profile
}

proxy_test(){
	echo -e "\033[42;31m Test proxy ... \033[0m"
	curl -I www.google.com 
}

main(){
	echo -e "\033[42;31m Welcome use one key shadowsocks client config shell \033[0m"
	echo -e "\033[42;31m Start config shadowsocks client ... \033[0m"

	prepare
	ss_conf
	ss_service
	ss_test
	privoxy_conf
	proxy_conf
	proxy_test
}

main
