#!/bin/bash

AcidantheraRepo=(
	Lilu
	AppleALC
	WhateverGreen
#	VirtualSMC
	CPUFriend
	AirportBrcmFixup
	RTCMemoryFixup
	HibernationFixup
	DebugEnhancer
	BT4LEContinuityFixup
)

## Prepare directory to store build product
prepare(){
	cd ~
	mkdir -p ~/Downloads/自编译Kexts
	curl -Lfs https://raw.githubusercontent.com/acidanthera/Lilu/master/Lilu/Scripts/bootstrap.sh -o /tmp/bootstrap.sh
	chmod +x /tmp/bootstrap.sh
	for i in "${AcidantheraRepo[@]}"
	do
		if [[ ! -d "$i" ]] ; then
			echo -e "\033[41;33m $i 不存在，开始下载... \033[0m"
			git clone https://github.com/acidanthera/$i
		fi
	done
	if [[ ! -d "VirtualSMC" ]] ; then
		echo -e "\033[41;33m VirtualSMC 不存在，开始下载... \033[0m"
		git clone https://github.com/acidanthera/VirtualSMC
	fi
}

## Build all Lilu and its pluglns
buildAll(){
	cd ~
	for i in "${AcidantheraRepo[@]}"
	do
		echo -e "\033[41;33m 开始编译 $i ... \033[0m"
		sleep 3
		cd "$i" && rm -rf Lilu.kext
		git pull
		if [[ "$1" != "Lilu" ]] ; then
			eval /tmp/bootstrap.sh
		fi
		xcodebuild -configuration Debug
		xcodebuild -configuration Release
		mv build/Debug/*.zip ~/Downloads/自编译Kexts/
		mv build/Release/*.zip ~/Downloads/自编译Kexts/
		cd ~
	done
	
	echo -e "\033[41;33m 开始编译 VirtualSMC ... \033[0m"
	sleep 3
	cd ~/VirtualSMC && rm -rf Lilu.kext
	git pull
	eval /tmp/bootstrap.sh
	xcodebuild -target Package -configuration Debug
	xcodebuild -target Package -configuration Release
	mv build/Debug/*.zip ~/Downloads/自编译Kexts/
	mv build/Release/*.zip ~/Downloads/自编译Kexts/
	cd ~
}

## Build according arguments
rbuild(){
	if [[ "$1" == "VirtualSMC" ]] ; then
		echo -e "\033[41;33m 开始编译 VirtualSMC ... \033[0m"
		sleep 3
		cd "$1" && rm -rf Lilu.kext
		git pull
		eval /tmp/bootstrap.sh
		xcodebuild -target Package -configuration Debug
		xcodebuild -target Package -configuration Release
		mv build/Debug/*.zip ~/Downloads/自编译Kexts/
		mv build/Release/*.zip ~/Downloads/自编译Kexts/
	else
		echo -e "\033[41;33m 开始编译 $1 ... \033[0m"
		sleep 3
		cd "$1" && rm -rf Lilu.kext
		git pull
		if [[ "$1" != "Lilu" ]] ; then
			eval /tmp/bootstrap.sh
		fi
		xcodebuild -configuration Debug
		xcodebuild -configuration Release
		mv build/Debug/*.zip ~/Downloads/自编译Kexts/
		mv build/Release/*.zip ~/Downloads/自编译Kexts/
	fi
}

## Main Method
main(){
	prepare
	if [[ "$#" -eq "0" ]] ; then
		buildAll
	else
		rbuild "$1"
	fi
	
	## Delete tmp files
	rm -rf /tmp/bootstrap.sh
	
	open ~/Downloads/自编译Kexts/
}

main "$@"
