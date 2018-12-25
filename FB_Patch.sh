############################################################
#                   Created by Canvas                      #
#                    Author: Canvas                        #
#             Site: https://blog.iamzhl.top/               #
#               Email: 1143991340@qq.com                   #
############################################################

#!/bin/bash

# Define variable
var(){
	fbname=$(kextstat | grep -o "AppleIntel.*Framebuffer[^ ]*")
	igid=$(ioreg -l | grep ig-platform-id | sed "s/.*<\([^>]*\)>.*/\1/g")
	org=$(xxd -ps /S*/L*/E*/$fbname.kext/C*/M*/$fbname | tr -d '\n' | grep -Eo "${igid}0.*?00000060" | sed "s/$igid//g")
	patch=$(echo $org | sed 's/\(.*\)00000060\(.*\)/\100000080\2/')
	gpu=$(system_profiler SPDisplaysDataType | awk -F': ' '/^\ *Chipset Model:/ {printf $2}')
	osversion=$(sw_vers -productVersion)
	shortversion=$(sw_vers -productVersion | cut -b 1,2,3,4,5)
}

# Reverse igid
rev(){
	ig4=$(echo $igid | cut -c 1,2) 
	ig3=$(echo $igid | cut -c 3,4) 
	ig2=$(echo $igid | cut -c 5,6) 
	ig1=$(echo $igid | cut -c 7,8) 
	igid="0x$ig1$ig2$ig3$ig4"
}

# Get patch
highPatch(){
	hexfind=$(echo $org | sed "s/.\{8\}/& /g")
	hexreplace=$(echo $patch | sed "s/.\{8\}/& /g")
	base64find=$(echo $org | xxd -r -p | base64)
	base64replace=$(echo $patch | xxd -r -p | base64)
	comment=$(echo "Change VRAM 1536 -> 2048 for $igid")
	matchos=$(sw_vers -productVersion)
}

# Print Message
printMsg(){
	echo -e "\n=================================================================>"
	echo -e "Your GPU model is: 		$gpu"
	echo -e "Your GPU fbname is: 		$fbname"
	echo -e "Your ig-platform-id is: 	$igid"
	echo -e "Your macOS version is: 		$osversion"
	echo -e "<================================================================="
	echo -e "\nThe VRAM patch are here: "
}

# Patch for hex
hexPatch(){
	echo -e "=================================================================>"
	echo -e "hex format ......"
	echo -e "Name:		$fbname"
	echo -e "Find:		$hexfind"
	echo -e "Replace:	$hexreplace"
	echo -e "Comment:	$comment"
	echo -e "MatchOS:	$matchos"
	echo -e "<================================================================="
	echo -e "\n"
}

# Patch for base64
base64Patch(){
	echo -e "=================================================================>"
	echo -e "base64 format ......"
	echo -e "Name:		$fbname"
	echo -e "Find:		$base64find"
	echo -e "Replace:	$base64replace"
	echo -e "Comment:	$comment"
	echo -e "MatchOS:	$matchos"
	echo -e "<================================================================="
	echo -e "\n"
}

# Patch for device properties
mojavePatch(){
	echo -e "=================================================================>"
	echo -e "Device Properties ......"
	echo -e "Properties Keys\t\t\tProperties Value\t\tValue Type"
	echo -e "-----------------------\t\t---------------------\t\t-----------"
	echo -e "AAPL,slot-name\t\t\tPCI Express 3.0\t\t\tSTRING"
	echo -e "framebuffer-patch-enable\t01000000\t\t\tDATA"
	echo -e "framebuffer-unifiedmem\t\t00000080\t\t\tDATA"
	echo -e "AAPL,ig-platform-id\t\t$igid\t\t\tDATA"
	echo -e "framebuffer-con1-enable\t\t01000000\t\t\tDATA"
	echo -e "hda-gfx\t\t\t\tonboard-1\t\t\tSTRING"
	echo -e "model\t\t\t\t$gpu\tSTRING"
	echo -e "<================================================================="
	echo -e "\n"
}

main(){
	var
	rev
	printMsg
	if [[ $shortversion == "10.14" ]] ; then
		mojavePatch
	else
		highPatch
		hexPatch
		base64Patch
	fi
	echo -e "Enjoy, have a nice day!\n"
}

main

exit 0