############################################################
#                   Created by Canvas                      #
#                    Author: Canvas                        #
#             Site: https://blog.iamzhl.top/               #
#               Email: 1143991340@qq.com                   #
############################################################

#!/bin/bash

read -t 30 -p "Input you choice(yes/or): " choice 

case "$choice" in 
	"yes") 
		echo "Your choice is yes" 
		;;
	"no") 
		echo "Your choice is no" 
		;;
	*) 
		echo "Your choice is error" 
		;;
esac