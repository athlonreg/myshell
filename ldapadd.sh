#!/bin/bash

read -p "Input mail domain(Default is example.com): " domain

if [[ $domain == "" ]] ; then
	domain=example.com
fi

SUFFIX=$(echo dc=$(echo $domain | awk -F '.' '{print $1}'),dc=$(echo $domain | awk -F '.' '{print $2}'))

cd /root/GeoDevOPS
sed -i -e "s/example.com/$domain/g" ldaptemplate.ldif
sed -i -e "s/dc=example,dc=com/$SUFFIX/g" ldaptemplate.ldif
read -p "Input username: " username
read -p "Input password: " password
useradd $username && echo $password | passwd $username --stdin
cp ldaptemplate.ldif ${username}.ldif
sed -i -e "s/template/$username/g" ${username}.ldif
sed -i "11i userPassword: $(slappasswd -s $password)" ${username}.ldif

ldapadd -x -D "cn=Manager,$SUFFIX" -W -f ${username}.ldif

echo "Finished successfully!"
printf "username\tpassword\n" | column -t
printf "$username\t$password\n" | column -t 
