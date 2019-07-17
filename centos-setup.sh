#!/bin/bash

update(){
	cd /usr/local
	wget http://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
	rpm -ivh mysql57-community-release-el7-11.noarch.rpm
	touch /etc/yum.repos.d/nginx.repo
	echo -e "
	[nginx]
	name=nginx repo
	baseurl=http://nginx.org/packages/mainline/centos/7/$basearch/
	gpgcheck=0
	enabled=1
	" > /etc/yum.repos.d/nginx.repo
	yum update -y 
}

firewall(){
	sed -i -e "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
	systemctl stop firewalld
	systemctl disable firewalld
	setenforce 0
}

common(){
	yum -y install ntsysv vim unzip zlib pcre gcc-c++ openssl pcre-devel
}

network(){
	yum -y install wget net-tools lsof
}

httpd(){
	yum -y install httpd
	systemctl enable httpd
	systemctl start httpd
}

nginx(){
	yum -y install nginx
	sed -i -e "s/80/81/g" /etc/nginx/conf.d/default.conf
	systemctl enable nginx
	systemctl start nginx
}

mysql(){
	yum -y install mysql mysql-devel mysql-server
	systemctl start mysqld
	systemctl enable mysqld
}

jenkins(){
	yum -y install jenkins
}

php56w(){
	cd /usr/local
	wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	wget https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
	rpm -ivh *.rpm
	yum -y install libicu libicu-devel libicu-doc
	yum -y install `yum search php | grep php56w | grep -v mysqlnd | awk -F '.' '{print $1}'`
}

# Tomcat MAVEN ANT
apache(){
	cd /usr/local
	
	wget https://gitlab.com/Syncanvas/mcs/raw/master/jdk-8u161-linux-x64.rpm\?inline\=false
	mv jdk-8u161-linux-x64.rpm\?inline\=false jdk-8u161-linux-x64.rpm
	rpm -ivh jdk-8u161-linux-x64.rpm
	wget http://mirrors.shu.edu.cn/apache/tomcat/tomcat-9/v9.0.14/bin/apache-tomcat-9.0.14.tar.gz
	tar zxvf apache-tomcat-9.0.14.tar.gz
	mv apache-tomcat-9.0.14 tomcat
	wget http://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.6.0/binaries/apache-maven-3.6.0-bin.tar.gz
	tar zxvf apache-maven-3.6.0-bin.tar.gz
	mv apache-maven-3.6.0-bin maven
	wget http://mirror.bit.edu.cn/apache//ant/binaries/apache-ant-1.10.5-bin.tar.gz
	tar zxvf apache-ant-1.10.5-bin.tar.gz
	mv apache-ant-1.10.5-bin ant
	
	echo -e "
	touch /usr/local/tomcat/bin/startup.sh
	" >> /etc/rc.local
	echo -e "
	export JAVA_HOME=/usr/java/jdk1.8.0_161
	export JRE_HOME=$JAVA_HOME/jre
	export CLASSPATH=$JAVA_HOME/lib
	export TOMCAT_HOME=/usr/local/tomcat
	export CATALINA_HOME=/usr/local/tomcat
	export ANT_HOME=/usr/local/ant
	export MAVEN_HOME=/usr/local/maven
	export M2_HOME=/usr/local/maven
	export PATH=$PATH:/usr/local/maven/bin:/usr/local/ant/bin:/usr/local/tomcat/bin:$JAVA_HOME/bin:$JRE_HOME/bin:$CLASSPATH
	" >> /etc/profile && source /etc/profile
	
	startup.sh
}

git2u(){
	cd /usr/local
	wget https://centos7.iuscommunity.org/ius-release.rpm
	rpm -ivh ius-release.rpm
	yum install -y git2u gitweb
}

main(){
	update
	firewall
	common
	network
	httpd
	nginx
	mysql
	apache
	jenkins
	php56w
	apache
	git2u
}

main
