############################################################
#                   Created by Canvas                      #
#                    Author: Canvas                        #
#             Site: https://blog.iamzhl.top/               #
#               Email: 1143991340@qq.com                   #
############################################################

#!/bin/bash

read -p "Are you have install nodejs ? (yes / no) "  choice
if [[ ${choice} == "yes" || ${choice} == "y" ]] ; then
	npm update
	echo "Installing docsite, please wait a while ..."
	npm i -g docsite
	echo -e "Docsite installed done!\nCreate a directory named 'my_docsite_project, you can find your site in this dir ^_^'"
	mkdir my_docsite_project && cd my_docsite_project && docsite init
	docsite start
else
	echo "Please install nodejs that version must higher than 6.0 ..."
	exit
fi
	
