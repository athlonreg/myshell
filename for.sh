#!/bin/bash

read -t 30 -p "Input a dir to unzip or ungz: " dir 

if [[ -d $dir ]] ; then 
	cd $dir 

	for i in $( ls *.zip ) 
	do 
		unzip $i & > /dev/null 
	done

	for j in $( ls *.tar.gz ) 
	do 
		tar zxf $j & > /dev/null 
	done

	for k in $( ls *.tgz ) 
	do 
		unzip $k & > /dev/null 
	done
else 
	echo "$dir 不是目录"
	exit 1
fi
