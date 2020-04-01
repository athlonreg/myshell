#!/bin/bash

## Install some tools
baseinstall(){
	yum -y install wget lsof net-tools
}

## PG install
pginstall(){
	## Download rpm source
	cd ~
	mkdir pg_down && cd pg_down
	for i in $(curl -s https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/ | awk -F '>' '{print $4}' | tr -s '\n' | sed 's/<\/a//g' | grep 'postgre' | grep '11.2-2')
	do
		wget https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/$i
	done

	## Local install
	if [[ $? -eq 0 ]] ; then
		yum localinstall -y *.rpm --skip-broken
	fi

	## Initialize database
	/usr/pgsql-11/bin/postgresql-11-setup initdb || exit 1

	## Setup start and autoboot
	systemctl enable postgresql-11 || exit 1
	systemctl start postgresql-11 || exit 1

	## Setup listen port and listen address and md5 auth
	echo "host    all             all             all                     md5" >> /var/lib/pgsql/11/data/pg_hba.conf
	echo "listen_addresses = '*'" >> /var/lib/pgsql/11/data/postgresql.conf
	echo "port = 5431" >> /var/lib/pgsql/11/data/postgresql.conf

	## Restart to make setup enable
	systemctl restart postgresql-11 || exit 1

	## Change password
	read -p "Input pg password you want to set: " passwd
	sudo -u postgres psql -p 5431 --command "alter role postgres with password '$passwd';"
	## Change password
	## psql> alter role postgres with password 'newpassword';
	## psql> \q
}

main(){
	baseinstall
	pginstall
}

main
