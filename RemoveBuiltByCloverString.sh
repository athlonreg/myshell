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
echo "+++++++++++       Start extract and patch CLOVERX64.efi...      +++++++++++" 
echo "+++++++++++                                                     +++++++++++" 
echo "+++++++++++                                                     +++++++++++" 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 

cd ~/Desktop/ 
cp /Volumes/EFI/EFI/CLOVER/CLOVERX64.efi ./CLOVERX64.efi 
cp /Volumes/EFI/EFI/CLOVER/CLOVERX64.efi ./CLOVERX64-Patch.efi 
perl -i -pe 's|\x42\x75\x69\x6c\x74\x20\x62\x79\x3a\x20\x20\x20\x20\x20\x43\x6c\x6f\x76\x65\x72|\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00|sg' CLOVERX64-Patch.efi

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
echo "++++++                                                               ++++++" 
echo "++++++ The origin and nolog CLOVERX64.efi have been put in Desktop!!!++++++" 
echo "++++++                     Have a nice day ´◡\`                      ++++++" 
echo "++++++                                                               ++++++" 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
