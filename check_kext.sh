############################################################
#                   Created by Canvas                      #
#                    Author: Canvas                        #
#             Site: https://blog.iamzhl.top/               #
#               Email: 1143991340@qq.com                   #
############################################################

#!/bin/bash
kextstat | grep -v "com.apple" | grep -v Energy | awk '{print $6 "\t" $7}' 
