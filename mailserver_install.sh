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
	echo "All files will be custom backup finished......"

	sed -i -e "$ a myhostname = mail.$domain" /etc/postfix/main.cf 
	sed -i -e "$ a mydomain = $domain" /etc/postfix/main.cf 
	sed -i -e "$ a myorigin = \$mydomain" /etc/postfix/main.cf 
	sed -i -e "$ a inet_interfaces = all" /etc/postfix/main.cf 
	sed -i -e "$ a inet_protocols = ipv4" /etc/postfix/main.cf 
	sed -i -e "$ a mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain" /etc/postfix/main.cf 
	sed -i -e "$ a mynetworks = 127.0.0.0/8, 10.0.0.0/24" /etc/postfix/main.cf 
	sed -i -e "$ a alias_maps = hash:/etc/aliases,$virtual_alias_maps" /etc/postfix/main.cf 
	sed -i -e "$ a alias_database = $alias_maps" /etc/postfix/main.cf 
	sed -i -e "$ a home_mailbox = /home/vmail/Maildir" /etc/postfix/main.cf 
	sed -i -e "$ a smtp_banner = \$myhostname ESMTP \$mail_name" /etc/postfix/main.cf 
	echo -e "message_size_limit = 157286400\nmailbox_size_limit = 314572800\nsmtpd_sasl_auth_enable = yes\nsmtpd_sasl_type = dovecot\nsmtpd_sasl_type = dovecot\nsmtpd_sasl_path = private/auth\nsmtpd_sasl_security_options = noanonymous\nsmtpd_sasl_local_domain = $myhostname\nsmtpd_sender_login_maps = ldap:/etc/postfix/ldap_alias_maps.cf,ldap:/etc/postfix/ldap-users.cf\nsmtpd_recipient_restrictions = permit_mynetworks,permit_auth_destination,permit_sasl_authenticated,reject\n\nvirtual_alias_maps = ldap:/etc/postfix/ldap_alias_maps.cf\nvirtual_mailbox_domains = ${domain}\nvirtual_mailbox_base = /home/vmail/\nvirtual_mailbox_maps = ldap:/etc/postfix/ldap-users.cf\nvirtual_uid_maps = static:5000\nvirtual_gid_maps = static:5000\nvirtual_mailbox_limit = 314572800\nvirtual_transport = virtual\nlocal_recipient_maps = \$virtual_alias_maps\n" >> /etc/postfix/main.cf 
	
	echo "#" > /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a server_host = ldap://127.0.0.1" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a version = 3" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a search_base = $base" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a bind = yes" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a bind_dn = cn=Manager,$base" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a bind_pw = 123456" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a query_filter = (&(objectClass=inetOrgPerson)(initials=%s))" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a result_attribute = uid" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a search_base = ou=admin,$base" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a query_filter = (&(objectClass=inetOrgPerson)(uid=%u))" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a result_attribute = uid" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a search_base = ou=config,$base" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a query_filter = (&(objectClass=inetOrgPerson)(uid=%u))" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a result_attribute = uid" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a search_base = ou=developer,$base" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a query_filter = (&(objectClass=inetOrgPerson)(uid=%u))" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a result_attribute = uid" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a search_base = ou=test,$base" /etc/postfix/ldap_alias_maps.cf
	sed -i -e "$ a result_format = %s/Maildir/" /etc/postfix/ldap_alias_maps.cf

	echo "#" > /etc/postfix/ldap-users.cf
	sed -i -e "$ a server_host = 127.0.0.1" /etc/postfix/ldap-users.cf
	sed -i -e "$ a search_base = $base" /etc/postfix/ldap-users.cf
	sed -i -e "$ a version = 3" /etc/postfix/ldap-users.cf
	sed -i -e "$ a query_filter = (&(objectClass=inetOrgPerson)(uid=%u))" /etc/postfix/ldap-users.cf
	sed -i -e "$ a result_attribute = uid" /etc/postfix/ldap-users.cf
	sed -i -e "$ a result_format = %s/Maildir/" /etc/postfix/ldap-users.cf
	sed -i -e "$ a bind = yes" /etc/postfix/ldap-users.cf
	sed -i -e "$ a bind_dn = cn=Manager,$base" /etc/postfix/ldap-users.cf
	sed -i -e "$ a bind_pw = 123456" /etc/postfix/ldap-users.cf
}

dovecot_config(){
	echo "Backup all files will be custom......"
	cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.bak 
	cp /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.bak 
	cp /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.bak 
	cp /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.bak 
	cp /etc/dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf.bak 
	mv /etc/dovecot/conf.d/auth-ldap.conf.ext /etc/dovecot/conf.d/auth-ldap.conf.ext.bak 
	echo "All files will be custom backup finished......"

	sed -i -e "$ a listen = *" /etc/dovecot/dovecot.conf 
	sed -i -e "$ a disable_plaintext_auth = no" /etc/dovecot/conf.d/10-auth.conf
	sed -i -e "$ a auth_username_format = %Lu" /etc/dovecot/conf.d/10-auth.conf
	sed -i -e "$ a auth_mechanisms = plain login" /etc/dovecot/conf.d/10-auth.conf
	sed -i -e "$ a \!include auth-ldap.conf.ext" /etc/dovecot/conf.d/10-auth.conf
	sed -i -e "$ a mail_location = maildir:/home/vmail/%u/Maildir" /etc/dovecot/conf.d/10-mail.conf
	sed -i -e "$ a mail_uid = vmail" /etc/dovecot/conf.d/10-mail.conf
	sed -i -e "$ a mail_gid = vmail" /etc/dovecot/conf.d/10-mail.conf
	sed -i -e "100i\  unix_listener /var/spool/postfix/private/auth {\n\tmode = 0660\n\tuser = postfix\n\tgroup = postfix\n  }" /etc/dovecot/conf.d/10-master.conf
	sed -i -e "$ a ssl = no" /etc/dovecot/conf.d/10-ssl.conf 

	echo "#" > /etc/dovecot/conf.d/auth-ldap.conf.ext
	sed -i -e "$ a auth_username_format = %Lu" /etc/dovecot/conf.d/auth-ldap.conf.ext
	sed -i -e "$ a passdb {" /etc/dovecot/conf.d/auth-ldap.conf.ext
	sed -i -e "$ a   driver = ldap" /etc/dovecot/conf.d/auth-ldap.conf.ext
	sed -i -e "$ a   args = /etc/dovecot/dovecot-ldap.conf.ext" /etc/dovecot/conf.d/auth-ldap.conf.ext
	sed -i -e "$ a }" /etc/dovecot/conf.d/auth-ldap.conf.ext
	sed -i -e "$ a userdb {" /etc/dovecot/conf.d/auth-ldap.conf.ext
	sed -i -e "$ a   driver = static" /etc/dovecot/conf.d/auth-ldap.conf.ext
	sed -i -e "$ a   args = uid=vmail gid=vmail home=/home/vmail/%u" /etc/dovecot/conf.d/auth-ldap.conf.ext
	sed -i -e "$ a }" /etc/dovecot/conf.d/auth-ldap.conf.ext

	echo "#" > /etc/dovecot/dovecot-ldap.conf.ext
	sed -i -e "$ a hosts = 127.0.0.1:389" /etc/dovecot/dovecot-ldap.conf.ext
	sed -i -e "$ a base = $base" /etc/dovecot/dovecot-ldap.conf.ext
	sed -i -e "$ a ldap_version = 3" /etc/dovecot/dovecot-ldap.conf.ext
	sed -i -e "$ a auth_bind = yes" /etc/dovecot/dovecot-ldap.conf.ext
	sed -i -e "$ a dn = cn=Manager,$base" /etc/dovecot/dovecot-ldap.conf.ext
	sed -i -e "$ a dnpass = 123456" /etc/dovecot/dovecot-ldap.conf.ext
	sed -i -e "$ a deref = never" /etc/dovecot/dovecot-ldap.conf.ext
	sed -i -e "$ a scope = subtree" /etc/dovecot/dovecot-ldap.conf.ext
	sed -i -e "$ a sasl_bind = no" /etc/dovecot/dovecot-ldap.conf.ext
	sed -i -e "$ a tls = no" /etc/dovecot/dovecot-ldap.conf.ext
	sed -i -e "$ a user_filter = (&(objectClass=posixAccount)(uid=%u))" /etc/dovecot/dovecot-ldap.conf.ext
	sed -i -e "$ a pass_filter = (&(objectClass=inetOrgPerson)(uid=%u))" /etc/dovecot/dovecot-ldap.conf.ext
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
	dc1=$(echo $domain|awk -F '.' '{print $1}')
	dc2=$(echo $domain|awk -F '.' '{print $2}')
	base=dc=$dc1,dc=$dc2
	addhosts
	postfix_install
	dovecot_install
	sendmail_remove
	postfix_config
	dovecot_config
	start
}

main
