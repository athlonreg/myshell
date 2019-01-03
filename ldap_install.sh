#!/bin/bash

yum_install(){
	echo "Installing openldap openldap-servers and openldap-clients......"
	yum -y install openldap-servers openldap-clients
}

start(){
	echo "Config openldap to start and autoboot......"
	systemctl start slapd
	systemctl enable slapd
}

db_config(){
	echo "Config openldap db......"
	cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
	chown ldap:ldap /var/lib/ldap/DB_CONFIG
}

domain_setup(){
	read -p "Input mail domain(Default is example.com): " domain
	read -p "Input organization you want to setup(Default is Example): " oOfBaseDomain
	read -p "Input dc you want to setup(Default is Example): " dcOfBaseDomain

	if [[ $domain == "" ]] ; then
		domain=example.com
	fi
	if [[ $oOfBaseDomain == "" ]] ; then
		oOfBaseDomain=Example
	fi
	if [[ $dcOfBaseDomain == "" ]] ; then
		dcOfBaseDomain=Example
	fi

	export SUFFIX=$(echo dc=$(echo $domain | awk -F '.' '{print $1}'),dc=$(echo $domain | awk -F '.' '{print $2}'))
}

slapd_config(){
	echo "Changing root dn password......"
	read -p "Input root dn password you want to set: " password
	olcRootPW=$(slappasswd -s $password)
	echo -e "#specify the password generated above for \"olcRootPW\" section\ndn: olcDatabase={0}config,cn=config\nchangetype: modify\nadd: olcRootPW\nolcRootPW: $olcRootPW" > chrootpw.ldif
	ldapadd -Y EXTERNAL -H ldapi:/// -f chrootpw.ldif

	echo "Importing base schema......"
	for i in `ls /etc/openldap/schema/*.ldif`
	do
		if [[ $i != /etc/openldap/schema/core.ldif ]] ; then
			ldapadd -Y EXTERNAL -H ldapi:/// -f $i
		fi
	done

	echo "Setuping password for chdomain.ldif......"
	read -p "Input password for chdomain.ldif you want to set: " password
	olcRootPW=$(slappasswd -s $password)
	echo -e "# replace to your own domain name for \"dc=***, dc=***\" section\n# specify the password generated above for \"olcRootPW\" section\ndn: olcDatabase={1}monitor,cn=config\nchangetype: modify\nreplace: olcAccess\nolcAccess: {0}to * by dn.base=\"gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth\" read by dn.base=\"cn=Manager,$SUFFIX\" read by * none\n\ndn: olcDatabase={2}hdb,cn=config\nchangetype: modify\nreplace: olcSuffix\nolcSuffix: $SUFFIX\n\ndn: olcDatabase={2}hdb,cn=config\nchangetype: modify\nreplace: olcRootDN\nolcRootDN: cn=Manager,$SUFFIX\n\ndn: olcDatabase={2}hdb,cn=config\nchangetype: modify\nreplace: olcRootPW\nolcRootPW: $olcRootPW\n\ndn: olcDatabase={2}hdb,cn=config\nchangetype: modify\nadd: olcAccess\nolcAccess: {0}to attrs=userPassword,shadowLastChange by dn=\"$SUFFIX\" write by anonymous auth by self write by * none\nolcAccess: {1}to dn.base=\"\" by * read\nolcAccess: {2}to * by dn=\"$SUFFIX\" write by * read" > chdomain.ldif
	ldapmodify -Y EXTERNAL -H ldapi:/// -f chdomain.ldif

	echo "Setuping basedomain configuration......"
	echo -e "# replace to your own domain name for \"dc=***,dc=***\" section\ndn: $SUFFIX\nobjectClass: top\nobjectClass: dcObject\nobjectClass: organization\no: ${oOfBaseDomain}\ndc: ${dcOfBaseDomain}\n\ndn: cn=Manager,$SUFFIX\nobjectClass: organizationalRole\ncn: Manager\ndescription: Directory Manager\n\ndn: ou=People,$SUFFIX\nobjectClass: organizationalUnit\nou: People\n\ndn: ou=Group,$SUFFIX\nobjectClass: organizationalUnit\nou: Group" > basedomain.ldif
	ldapadd -x -D cn=Manager,dc=$(echo $domain | awk -F '.' '{print $1}'),dc=$(echo $domain | awk -F '.' '{print $2}') -W -f basedomain.ldif

	read -p "Want you add an user now?(y / n) " option
	if [[ $option == "yes" || $option == "y" ]] ; then
		echo "Add an user......"
		read -p "Input username: " username
		read -p "Input password: " password
		useradd $username && echo $password | passwd $username --stdin
		echo -e "dn: uid=$username,ou=People,dc=$(echo $domain | awk -F '.' '{print $1}'),dc=$(echo $domain | awk -F '.' '{print $2}')\nobjectClass: inetOrgPerson\nobjectClass: posixAccount\nobjectClass: shadowAccount\nsn: $username\ngivenName: $username\ncn: $username\ndisplayName: $username\nmail: $username@dc=$(echo $domain | awk -F '.' '{print $1}'),dc=$(echo $domain | awk -F '.' '{print $2}')\nuidNumber: 2529\ngidNumber: 2529\nloginShell: /bin/bash\nhomeDirectory: /home/$username\nshadowExpire: -1\nshadowFlag: 0\nshadowWarning: 7\nshadowMin: 0\nshadowMax: 99999\nshadowLastChange: 17793\n\ndn: cn=$username,ou=Group,dc=$(echo $domain | awk -F '.' '{print $1}'),dc=$(echo $domain | awk -F '.' '{print $2}')\nobjectClass: posixGroup\ncn: $username\ngidNumber: 2529\nmemberUid: $username" > $username.ldif
		ldapadd -x -D cn=Manager,dc=$(echo $domain | awk -F '.' '{print $1}'),dc=$(echo $domain | awk -F '.' '{print $2}') -W -f $username.ldif
	fi

	echo "Add all user of this computer......"
	echo -e "# extract local users and groups who have 1000-9999 digit UID" > ldapuser.sh
	echo -e "# replace \"SUFFIX=***\" to your own domain name" >> ldapuser.sh
	echo -e "# this is an example" >> ldapuser.sh
	sed -i -e "$ a #!/bin/bash\n" ldapuser.sh
	sed -i -e "$ a SUFFIX='$SUFFIX'\nLDIF='allUserOfThisComputer.ldif'\n" ldapuser.sh
	echo -e "echo -n > \$LDIF" >> ldapuser.sh
	echo -e "GROUP_IDS=()" >> ldapuser.sh
	echo -e "grep \"x:[1-9][0-9][0-9][0-9]:\" /etc/passwd | (while read TARGET_USER" >> ldapuser.sh
	echo -e "do" >> ldapuser.sh
	echo -e "\tUSER_ID=\"\$(echo \"\$TARGET_USER\" | cut -d':' -f1)\"" >> ldapuser.sh
	echo -e "\n\tUSER_NAME=\"\$(echo \"\$TARGET_USER\" | cut -d':' -f5 | cut -d' ' -f1,2)\"" >> ldapuser.sh
	echo -e "\t[ ! \"\$USER_NAME\" ] && USER_NAME=\"\$USER_ID\"" >> ldapuser.sh
	echo -e "\n\tLDAP_SN=\"\$(echo \"\$USER_NAME\" | cut -d' ' -f2)\"" >> ldapuser.sh
	echo -e "\t[ ! \"\$LDAP_SN\" ] && LDAP_SN=\"\$USER_NAME\"" >> ldapuser.sh
	echo -e "\n\tLASTCHANGE_FLAG=\"\$(grep \"\${USER_ID}:\" /etc/shadow | cut -d':' -f3)\"" >> ldapuser.sh
	echo -e "\t[ ! \"\$LASTCHANGE_FLAG\" ] && LASTCHANGE_FLAG=\"0\"" >> ldapuser.sh
	echo -e "\n\tSHADOW_FLAG=\"\$(grep \"\${USER_ID}:\" /etc/shadow | cut -d':' -f9)\"" >> ldapuser.sh
	echo -e "\t[ ! \"\$SHADOW_FLAG\" ] && SHADOW_FLAG=\"0\"" >> ldapuser.sh
	echo -e "\n\tGROUP_ID=\"\$(echo \"\$TARGET_USER\" | cut -d':' -f4)\"" >> ldapuser.sh
	echo -e "\t[ ! \"\$(echo \"\${GROUP_IDS[@]}\" | grep \"\$GROUP_ID\")\" ] && GROUP_IDS=(\"\${GROUP_IDS[@]}\" \"\$GROUP_ID\")" >> ldapuser.sh
	echo -e "\n\techo \"dn: uid=\$USER_ID,ou=People,\$SUFFIX\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"objectClass: inetOrgPerson\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"objectClass: posixAccount\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"objectClass: shadowAccount\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"sn: \$LDAP_SN\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"givenName: \$(echo \"\$USER_NAME\" | awk '{print \$1}')\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"cn: \$USER_NAME\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"displayName: \$USER_NAME\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"uidNumber: \$(echo \"\$TARGET_USER\" | cut -d':' -f3)\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"gidNumber: \$(echo \"\$TARGET_USER\" | cut -d':' -f4)\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"userPassword: {crypt}\$(grep \"\${USER_ID}:\" /etc/shadow | cut -d':' -f2)\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"gecos: \$USER_NAME\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"loginShell: \$(echo \"\$TARGET_USER\" | cut -d':' -f7)\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"homeDirectory: \$(echo \"\$TARGET_USER\" | cut -d':' -f6)\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"shadowExpire: \$(passwd -S \"\$USER_ID\" | awk '{print \$7}')\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"shadowFlag: \$SHADOW_FLAG\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"shadowWarning: \$(passwd -S \"\$USER_ID\" | awk '{print \$6}')\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"shadowMin: \$(passwd -S \"\$USER_ID\" | awk '{print \$4}')\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"shadowMax: \$(passwd -S \"\$USER_ID\" | awk '{print \$5}')\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"shadowLastChange: \$LASTCHANGE_FLAG\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo >> \$LDIF" >> ldapuser.sh
	echo -e "done" >> ldapuser.sh
	echo -e "\nfor TARGET_GROUP_ID in \"\${GROUP_IDS[@]}\"" >> ldapuser.sh
	echo -e "do" >> ldapuser.sh
	echo -e "\tLDAP_CN=\"\$(grep \":\${TARGET_GROUP_ID}:\" /etc/group | cut -d':' -f1)\"" >> ldapuser.sh
	echo -e "\n\techo \"dn: cn=\$LDAP_CN,ou=Group,\$SUFFIX\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"objectClass: posixGroup\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"cn: \$LDAP_CN\" >> \$LDIF" >> ldapuser.sh
	echo -e "\techo \"gidNumber: \$TARGET_GROUP_ID\" >> \$LDIF" >> ldapuser.sh
	echo -e "\n\tfor MEMBER_UID in \$(grep \":\${TARGET_GROUP_ID}:\" /etc/passwd | cut -d':' -f1,3)" >> ldapuser.sh
	echo -e "\tdo" >> ldapuser.sh
	echo -e "\t\tUID_NUM=\$(echo \"\$MEMBER_UID\" | cut -d':' -f2)" >> ldapuser.sh
	echo -e "\t\t[ \$UID_NUM -ge 1000 -a \$UID_NUM -le 9999 ] && echo \"memberUid: \$(echo \"\$MEMBER_UID\" | cut -d':' -f1)\" >> \$LDIF" >> ldapuser.sh
	echo -e "\tdone" >> ldapuser.sh
	echo -e "\techo >> \$LDIF" >> ldapuser.sh
	echo -e "done" >> ldapuser.sh
	echo -e ")" >> ldapuser.sh
	chmod +x ldapuser.sh
	sh ldapuser.sh
	ldapadd -x -D cn=Manager,dc=$(echo $domain | awk -F '.' '{print $1}'),dc=$(echo $domain | awk -F '.' '{print $2}') -W -f allUserOfThisComputer.ldif
}

workdir_setup(){
	cd /usr/local
	mkdir -p openldap && cd openldap
	echo "The directory will to use for installing openldap is $(pwd)"
}

main(){
	workdir_setup
	domain_setup
	yum_install
	db_config
	start
	slapd_config

	if [[ $? != 0 ]] ; then
		echo "Install error......"
		exit 1
	else
		echo "Finished install, successfully!"
		echo "Enjoy yourself!"
		exit 0
	fi
}

main
