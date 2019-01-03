#!/bin/bash

postfix_install(){
	echo "Installing postfix......"
	yum -y install postfix
}

dovecot_install(){
	echo "Installing dovecot......"
	yum -y install dovecot
}

sendmail_remove(){
	echo "Unstalling sendmail......"
	yum -y remove sendmail
}

postfix_config(){
	cp /etc/postfix/main.cf /etc/postfix/main.cf.bak 
	sed -i -e "$ a myhostname = mail.$domain" /etc/postfix/main.cf 
	sed -i -e "$ a mydomain = $domain" /etc/postfix/main.cf 
	sed -i -e "$ a myorigin = \$mydomain" /etc/postfix/main.cf 
	sed -i -e "$ a inet_interfaces = all" /etc/postfix/main.cf 
	sed -i -e "$ a inet_protocols = ipv4" /etc/postfix/main.cf 
	sed -i -e "$ a mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain" /etc/postfix/main.cf 
	sed -i -e "$ a mynetworks = 127.0.0.0/8, 10.0.0.0/24" /etc/postfix/main.cf 
	sed -i -e "$ a home_mailbox = Maildir/" /etc/postfix/main.cf 
	sed -i -e "$ a smtp_banner = \$myhostname ESMTP \$mail_name" /etc/postfix/main.cf 
	echo -e "smtpd_sasl_type = dovecot\nsmtpd_sasl_path = private/auth\nsmtpd_sasl_auth_enable = yes\nsmtpd_sasl_security_options = noanonymous\nsmtpd_sasl_local_domain = $myhostname\nsmtpd_recipient_restrictions = permit_mynetworks,permit_auth_destination,permit_sasl_authenticated,reject" >> /etc/postfix/main.cf 
}

dovecot_config(){
	echo "Backup all files will be custom......"
	cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.bak 
	cp /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.bak 
	cp /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.bak 
	cp /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.bak 
	echo "All files will be custom backup finished......"

	sed -i -e "$ a listen = *" /etc/dovecot/dovecot.conf 
	sed -i -e "$ a disable_plaintext_auth = no" /etc/dovecot/conf.d/10-auth.conf
	sed -i -e "$ a auth_mechanisms = plain login" /etc/dovecot/conf.d/10-auth.conf
	sed -i -e "$ a mail_location = maildir:~/Maildir" /etc/dovecot/conf.d/10-mail.conf
	sed -i -e "100i\  unix_listener /var/spool/postfix/private/auth {\n\tmode = 0666\n\tuser = postfix\n\tgroup = postfix\n  }" /etc/dovecot/conf.d/10-master.conf
}

start(){
	echo "Config postfix and dovecot to start and autoboot......"
	systemctl start postfix
	systemctl enable postfix
	systemctl start dovecot
	systemctl enable dovecot
}

addhosts(){
	echo "127.0.0.1   mail.$domain $domain" >> /etc/hosts
}

main(){
	read -p "Input the domain you want to use(Example example.com): " domain
	addhosts
	postfix_install
	dovecot_install
	sendmail_remove
	postfix_config
	dovecot_config
	start
}

main
