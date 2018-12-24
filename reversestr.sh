############################################################
#                   Created by Canvas                      #
#                    Author: Canvas                        #
#             Site: https://blog.iamzhl.top/               #
#               Email: 1143991340@qq.com                   #
############################################################

#!/bin/bash

igid=0600260a

ig4=$(echo $igid | cut -c 1,2) 
ig3=$(echo $igid | cut -c 3,4) 
ig2=$(echo $igid | cut -c 5,6) 
ig1=$(echo $igid | cut -c 7,8) 
igid="0x$ig1$ig2$ig3$ig4"
echo $igid