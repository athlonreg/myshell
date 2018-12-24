############################################################
#                   Created by Canvas                      #
#                    Author: Canvas                        #
#             Site: https://blog.iamzhl.top/               #
#               Email: 1143991340@qq.com                   #
############################################################

#!/bin/bash

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
echo "+++++++++++                                                     +++++++++++" 
echo "+++++++++++                                                     +++++++++++" 
echo "+++++++++++         Start extract and patch apfs.efi...         +++++++++++" 
echo "+++++++++++                                                     +++++++++++" 
echo "+++++++++++                                                     +++++++++++" 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 

cd ~/Desktop/ 
cp /usr/standalone/i386/apfs.efi ./apfs-origin.efi 
cp /usr/standalone/i386/apfs.efi ./apfs-nolog.efi 
perl -i -pe 's|\x00\x74\x07\xb8\xff\xff|\x00\x90\x90\xb8\xff\xff|sg' ./apfs-nolog.efi 

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
echo "++++++                                                               ++++++" 
echo "++++++   The origin and nolog apfs.efi have been put in Desktop!!!   ++++++" 
echo "++++++                     Have a nice day ´◡\`                       ++++++" 
echo "++++++                                                               ++++++" 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
