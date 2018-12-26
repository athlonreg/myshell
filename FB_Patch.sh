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
	org=$(xxd -ps /S*/L*/E*/${fbname}.kext/C*/M*/${fbname} | tr -d '\n' | grep -Eo "${igid}0.*?00000060" | sed "s/${igid}//g")
	patch=$(printf ${org} | sed 's/\(.*\)00000060\(.*\)/\100000080\2/')
	gpu=$(system_profiler SPDisplaysDataType | grep "Intel" | grep -v "Vendor" | grep -v "Chipset" | sed "s/://g" | cut -b 5-)
	osversion=$(sw_vers -productVersion)
	shortversion=$(sw_vers -productVersion | cut -b 1,2,3,4,5)
}

# Reverse igid
rev(){
	ig4=$(printf ${igid} | cut -c 1,2) 
	ig3=$(printf ${igid} | cut -c 3,4) 
	ig2=$(printf ${igid} | cut -c 5,6) 
	ig1=$(printf ${igid} | cut -c 7,8) 
	igid="0x$ig1$ig2$ig3$ig4"
}

# Get patch
highPatch(){
	hexfind=$(printf ${org} | sed "s/.\{8\}/& /g")
	hexreplace=$(printf $patch | sed "s/.\{8\}/& /g")
	base64find=$(printf ${org} | xxd -r -p | base64)
	base64replace=$(printf $patch | xxd -r -p | base64)
	comment=$(printf "Change VRAM 1536 -> 2048 for ${igid}")
	matchos=$(sw_vers -productVersion)
}

# Print Message
printMsg(){
	printf "\033[1m\033[37;41mYour Intel HD Graphics is here ......\033[0m\n"
	printTop
	printf "Your GPU model is:λ${gpu}\n"
	printf "Your GPU fbname is:λ${fbname}\n"
	printf "Your ig-platform-id is:λ${igid}\n"
	printf "Your macOS version is:λ${osversion}\n"
	printBottom
}

printTop(){
	printf "==========================>\n"
}

printBottom(){
	printf "<==========================\n"
}

printSeparator(){
	printf "\n---------------------------\n"
}

# Patch for hex
hexPatch(){
	printf "\033[1m\033[37;41mhex format ......\033[0m\n"
	printTop
	printf "Name:λ${fbname}\n"
	printf "Find:λ${hexfind}\n"
	printf "Replace:	λ$hexreplace\n"
	printf "Comment:	λ${comment}\n"
	printf "MatchOS:	λ${matchos}\n"
	printBottom
}

# Patch for base64
base64Patch(){
	printf "\033[1m\033[37;41mbase64 format ......\033[0m\n"
	printTop
	printf "Name:λ${fbname}\n"
	printf "Find:λ${base64find}\n"
	printf "Replace:	λ${base64replace}\n"
	printf "Comment:	λ${comment}\n"
	printf "MatchOS:	λ${matchos}\n"
	printBottom
}

# Patch for device properties
mojavePatch(){
	printf "\033[1m\033[37;41mDevice Properties ......\033[0m\n"
	printTop
	printf "Properties KeysλProperties ValueλValue Type"
	printf "\n---------------λ----------------λ----------\n"
	printf "AAPL,slot-nameλPCI Express 3.0λSTRING\n"
	printf "framebuffer-patch-enableλ01000000λDATA\n"
	printf "framebuffer-unifiedmemλ00000080λDATA\n"
	printf "AAPL,ig-platform-idλ${igid}λDATA\n"
	printf "framebuffer-con1-enableλ01000000λDATA\n"
	printf "hda-gfxλonboard-1λSTRING\n"
	printf "modelλ${gpu}λSTRING\n"
	printBottom
}

main(){
	var
	#rev
	printMsg
	printf "\033[1m\033[37;41mThe VRAM patch is here: \033[0m\n"
	printSeparator
	if [[ $shortversion == "10.14" ]] ; then
		mojavePatch
	else
		highPatch
		hexPatch
		base64Patch
	fi
	printf "Enjoy, have a nice day!\n"
}

main | column -t -s "λ"

exit 0