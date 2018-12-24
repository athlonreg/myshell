#################################################################
#		     Create by Canvas			  	  #
#		     Author: 	Canvas				  #
#		     Email:  	1143991340@qq.com		  #
#		     Site: 	https://blog.iamzhl.top/	  #
#################################################################
#!/bin/bash

read -p "Input a filename: " file 
if [[ -z "$file" ]] ; then 
	echo "Your input is null" 
	exit 1
elif [[ ! -e "$file" ]] ; then 
	echo "Your input is not a file" 
	exit 2
elif [[ -f "$file" ]] ; then 
	echo "Your input is a regular filename" 
elif [[ -d "$file" ]] ; then 
	echo "Youy input is a directory filename" 
elif [[ -L "$file" ]] ; then 
	echo "Youy input is a link filename" 
else 
	echo "Youy input is a other filename" 
fi