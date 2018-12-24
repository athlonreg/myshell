############################################################
#                   Created by Canvas                      #
#                    Author: Canvas                        #
#             Site: https://blog.iamzhl.top/               #
#               Email: 1143991340@qq.com                   #
############################################################

#!/bin/bash

# Define variable
fbname=$(kextstat | grep -o "AppleIntel.*Framebuffer[^ ]*")
igid=$(ioreg -l | grep ig-platform-id | sed "s/.*<\([^>]*\)>.*/\1/g")
org=$(xxd -ps /S*/L*/E*/$fbname.kext/C*/M*/$fbname | tr -d '\n' | grep -Eo "${igid}0.*?00000060" | sed "s/$igid//g")
patch=$(echo $org | sed 's/\(.*\)00000060\(.*\)/\100000080\2/')
gpu=$(system_profiler SPDisplaysDataType | awk -F': ' '/^\ *Chipset Model:/ {printf $2}')
osversion=$(sw_vers -productVersion)

# Reverse igid
ig4=$(echo $igid | cut -c 1,2) 
ig3=$(echo $igid | cut -c 3,4) 
ig2=$(echo $igid | cut -c 5,6) 
ig1=$(echo $igid | cut -c 7,8) 
igid="0x$ig1$ig2$ig3$ig4"

# Get patch
hexfind=$(echo $org | sed "s/.\{8\}/& /g")
hexreplace=$(echo $patch | sed "s/.\{8\}/& /g")
base64find=$(echo $org | xxd -r -p | base64)
base64replace=$(echo $patch | xxd -r -p | base64)
comment=$(echo "Change VRAM 1536 -> 2048 for $igid")
matchos=$(sw_vers -productVersion)

# Print Message
echo -e "\n=================================================================>"
echo -e "Your GPU model is: 		$gpu"
echo -e "Your GPU fbname is: 		$fbname"
echo -e "Your ig-platform-id is: 	$igid"
echo -e "Your macOS version is: 		$osversion"
echo -e "<================================================================="
echo -e "\nThe VRAM patch are here: "

# Patch for hex
echo -e "=================================================================>"
echo -e "hex format ......"
echo -e "Name:		$fbname"
echo -e "Find:		$hexfind"
echo -e "Replace:	$hexreplace"
echo -e "Comment:	$comment"
echo -e "MatchOS:	$matchos"
echo -e "<================================================================="
echo -e "\n"

# Patch for base64
echo -e "=================================================================>"
echo -e "base64 format ......"
echo -e "Name:		$fbname"
echo -e "Find:		$base64find"
echo -e "Replace:	$base64replace"
echo -e "Comment:	$comment"
echo -e "MatchOS:	$matchos"
echo -e "<================================================================="
echo -e "\n"

echo -e "Enjoy, have a nice day!\n"
exit 0