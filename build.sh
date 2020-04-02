#!/bin/bash

AcidantheraRepo=(
	Lilu
	AppleALC
	WhateverGreen
#	VirtualSMC
	NVMeFix
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
	if [[ ! -d "VoodooI2C" ]] ; then
		echo -e "\033[41;33m VoodooI2C 不存在，开始下载... \033[0m"
		git clone https://github.com/alexandred/VoodooI2C --recursive
	fi
	if [[ ! -d "VoodooPS2" ]] ; then
		echo -e "\033[41;33m VoodooPS2 不存在，开始下载... \033[0m"
		git clone https://github.com/acidanthera/VoodooPS2
	fi
	if [[ ! -d "VoodooInput" ]] ; then
		echo -e "\033[41;33m VoodooInput 不存在，开始下载... \033[0m"
		git clone https://github.com/acidanthera/VoodooInput
	fi
	if [[ ! -d "IntelMausi" ]] ; then
		echo -e "\033[41;33m IntelMausi 不存在，开始下载... \033[0m"
		git clone https://github.com/acidanthera/IntelMausi
	fi
	if [[ ! -d "BrcmPatchRAM" ]] ; then
		echo -e "\033[41;33m BrcmPatchRAM 不存在，开始下载... \033[0m"
		git clone https://github.com/acidanthera/BrcmPatchRAM
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
	
	## IntelMausi
	echo -e "\033[41;33m 开始编译 IntelMausi ... \033[0m"
	sleep 3
	cd ~/IntelMausi && git pull
	xcodebuild -configuration Debug
	xcodebuild -configuration Release
	mv build/Debug/*.zip ~/Downloads/自编译Kexts/
	mv build/Release/*.zip ~/Downloads/自编译Kexts/
	
	## VirtualSMC
	echo -e "\033[41;33m 开始编译 VirtualSMC ... \033[0m"
	sleep 3
	cd ~/VirtualSMC && rm -rf Lilu.kext
	git pull
	eval /tmp/bootstrap.sh
	xcodebuild -target Package -configuration Debug
	xcodebuild -target Package -configuration Release
	mv build/Debug/*.zip ~/Downloads/自编译Kexts/
	mv build/Release/*.zip ~/Downloads/自编译Kexts/
	
	## VoodooInput
	cd ~
	echo -e "\033[41;33m 开始编译 VoodooInput ... \033[0m"
	sleep 3
	cd VoodooInput && git pull
	xcodebuild -configuration Debug
	xcodebuild -configuration Release
	mv build/Debug/*.zip ~/Downloads/自编译Kexts/
	mv build/Release/*.zip ~/Downloads/自编译Kexts/
	
	## VoodooPS2
	cd ~
	echo -e "\033[41;33m 开始编译 VoodooPS2 ... \033[0m"
	sleep 3
	cd VoodooPS2 && git pull && git submodule init && git submodule update
	xcodebuild -configuration Debug
	xcodebuild -configuration Release
	mv build/Products/Debug/*.zip ~/Downloads/自编译Kexts/
	mv build/Products/Release/*.zip ~/Downloads/自编译Kexts/
	
	## VoodooI2C
	cd ~
	echo -e "\033[41;33m 开始编译 VoodooI2C ... \033[0m"
	sleep 3
	cd VoodooI2C && git pull && git submodule init && git submodule update
	version=$(cat VoodooI2C/VoodooI2C/Info.plist | grep -A 1 CFBundleVersion | grep string | sed 's/string//g' | sed 's/<//g' | sed 's/>//g' | sed 's/\///g' | awk '{print $1}')
	xcodebuild -workspace "VoodooI2C.xcworkspace" -scheme "VoodooI2C" -sdk macosx10.12 -derivedDataPath build clean build
	cd build/Build/Products/Release && zip -qry -FS "VoodooI2C-$version.zip" * || exit 1
	mv *.zip ~/Downloads/自编译Kexts/
	
	## BrcmPatchRAM
	cd ~
	echo -e "\033[41;33m 开始编译 BrcmPatchRAM ... \033[0m"
	sleep 3
	cd BrcmPatchRAM && git pull
	xcodebuild -configuration Debug -scheme BrcmPatchRAM
	xcodebuild -configuration Release -scheme BrcmPatchRAM
	cd build/Products/Debug
	zip -qry BrcmPatchRAM-$(cat ../../../BrcmPatchRAM.xcodeproj/project.pbxproj | grep -i 'CURRENT_PROJECT_VERSION' | head -1 | grep -oE '\d\.\d\.\d')-DEBUG.zip *.kext
	mv *.zip ~/Downloads/自编译Kexts/
	cd ../Release
	zip -qry BrcmPatchRAM-$(cat ../../../BrcmPatchRAM.xcodeproj/project.pbxproj | grep -i 'CURRENT_PROJECT_VERSION' | head -1 | grep -oE '\d\.\d\.\d')-RELEASE.zip *.kext
	mv *.zip ~/Downloads/自编译Kexts/
	cd -
	
	buildOther
}

## Build according arguments
rbuild(){
	if [[ "$1" == "VirtualSMC" ]] ; then
		## VirtualSMC
		echo -e "\033[41;33m 开始编译 $1 ... \033[0m"
		sleep 3
		cd "$1" && rm -rf Lilu.kext
		git pull
		eval /tmp/bootstrap.sh
		xcodebuild -target Package -configuration Debug
		xcodebuild -target Package -configuration Release
		mv build/Debug/*.zip ~/Downloads/自编译Kexts/
		mv build/Release/*.zip ~/Downloads/自编译Kexts/
	elif [[ "$1" == "IntelMausi" ]] ; then
		## IntelMausi
		echo -e "\033[41;33m 开始编译 IntelMausi ... \033[0m"
		sleep 3
		cd "$1" && git pull
		xcodebuild -configuration Debug
		xcodebuild -configuration Release
		mv build/Debug/*.zip ~/Downloads/自编译Kexts/
		mv build/Release/*.zip ~/Downloads/自编译Kexts/
	elif [[ "$1" == "VoodooInput" ]] ; then
		## VoodooInput
		echo -e "\033[41;33m 开始编译 $1 ... \033[0m"
		sleep 3
		cd "$1" && git pull
		xcodebuild -configuration Debug
		xcodebuild -configuration Release
		mv build/Debug/*.zip ~/Downloads/自编译Kexts/
		mv build/Release/*.zip ~/Downloads/自编译Kexts/
	elif [[ "$1" == "VoodooPS2" ]] ; then
		## VoodooPS2
		echo -e "\033[41;33m 开始编译 $1 ... \033[0m"
		sleep 3
		cd "$1" && git pull && git submodule init && git submodule update
		xcodebuild -configuration Debug
		xcodebuild -configuration Release
		mv build/Products/Debug/*.zip ~/Downloads/自编译Kexts/
		mv build/Products/Release/*.zip ~/Downloads/自编译Kexts/
	elif [[ "$1" == "VoodooI2C" ]] ; then
		## VoodooInput
		echo -e "\033[41;33m 开始编译 $1 ... \033[0m"
		sleep 3
		cd "$1" && git submodule init && git submodule update
		version=$(cat VoodooI2C/VoodooI2C/Info.plist | grep -A 1 CFBundleVersion | grep string | sed 's/string//g' | sed 's/<//g' | sed 's/>//g' | sed 's/\///g' | awk '{print $1}')
		xcodebuild -workspace "VoodooI2C.xcworkspace" -scheme "VoodooI2C" -sdk macosx10.12 -derivedDataPath build clean build
		cd build/Build/Products/Release && zip -qry -FS "VoodooI2C-$version.zip" * || exit 1
		mv *.zip ~/Downloads/自编译Kexts/
	elif [[ "$1" == "BrcmPatchRAM" ]] ; then
		## BrcmPatchRAM
		cd ~
		echo -e "\033[41;33m 开始编译 BrcmPatchRAM ... \033[0m"
		sleep 3
		cd BrcmPatchRAM && git pull
		xcodebuild -configuration Debug -scheme BrcmPatchRAM
		xcodebuild -configuration Release -scheme BrcmPatchRAM
		cd build/Products/Debug
		zip -qry BrcmPatchRAM-$(cat ../../../BrcmPatchRAM.xcodeproj/project.pbxproj | grep -i 'CURRENT_PROJECT_VERSION' | head -1 | grep -oE '\d\.\d\.\d')-DEBUG.zip *.kext
		mv *.zip ~/Downloads/自编译Kexts/
		cd ../Release
		zip -qry BrcmPatchRAM-$(cat ../../../BrcmPatchRAM.xcodeproj/project.pbxproj | grep -i 'CURRENT_PROJECT_VERSION' | head -1 | grep -oE '\d\.\d\.\d')-RELEASE.zip *.kext
		mv *.zip ~/Downloads/自编译Kexts/
		cd -
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

## Other
buildOther(){
	## MacProMemoryNotificationDisabler
	cd ~
	if [[ ! -d "MacProMemoryNotificationDisabler" ]] ; then
		echo -e "\033[41;33m MacProMemoryNotificationDisabler 不存在，开始下载... \033[0m"
		git clone https://github.com/IOIIIO/MacProMemoryNotificationDisabler
	fi
	echo -e "\033[41;33m 开始编译 MacProMemoryNotificationDisabler ... \033[0m"
	sleep 3
	cd ~/MacProMemoryNotificationDisabler && rm -rf Lilu.kext
	version=$(grep -r MODULE_VERSION MacProMemoryNotificationDisabler.xcodeproj/project.pbxproj | grep "[0-9]" | sed -n 1p | awk '{print $4}' | sed 's/;//g')
	git pull
	eval /tmp/bootstrap.sh
	xcodebuild -configuration Debug
	xcodebuild -configuration Release
	cd build/Release && zip -qry -FS "MacProMemoryNotificationDisabler-$version-RELEASE.zip" * || exit 1
	cd ../../build/Debug && zip -qry -FS "MacProMemoryNotificationDisabler-$version-DEBUG.zip" * || exit 1
	cd ../..
	mv build/Debug/*.zip ~/Downloads/自编译Kexts/
	mv build/Release/*.zip ~/Downloads/自编译Kexts/
	
	## ATH9KFixup
	cd ~
	if [[ ! -d "ATH9KFixup" ]] ; then
		echo -e "\033[41;33m ATH9KFixup 不存在，开始下载... \033[0m"
		git clone https://github.com/chunnann/ATH9KFixup
	fi
	echo -e "\033[41;33m 开始编译 ATH9KFixup ... \033[0m"
	sleep 3
	cd ~/ATH9KFixup && rm -rf Lilu.kext
	version=$(grep -r MODULE_VERSION ATH9KFixup.xcodeproj/project.pbxproj | grep "[0-9]" | grep -v '"' | sed -n 1p | awk '{print $4}' | sed 's/;//g')
	git pull
	eval /tmp/bootstrap.sh
	xcodebuild -configuration Debug
	xcodebuild -configuration Release
	cd build/Release && zip -qry -FS "ATH9KFixup-$version-RELEASE.zip" * || exit 1
	cd ../../build/Debug && zip -qry -FS "ATH9KFixup-$version-DEBUG.zip" * || exit 1
	cd ../..
	mv build/Debug/*.zip ~/Downloads/自编译Kexts/
	mv build/Release/*.zip ~/Downloads/自编译Kexts/
	git checkout .
	
	## DiskArbitrationFixup
	cd ~
	if [[ ! -d "DiskArbitrationFixup" ]] ; then
		echo -e "\033[41;33m DiskArbitrationFixup 不存在，开始下载... \033[0m"
		git clone https://github.com/Goldfish64/DiskArbitrationFixup
	fi
	echo -e "\033[41;33m 开始编译 DiskArbitrationFixup ... \033[0m"
	sleep 3
	cd ~/DiskArbitrationFixup && rm -rf Lilu.kext
	version=$(grep -rn MODULE_VERSION DiskArbitrationFixup.xcodeproj/project.pbxproj | grep "[0-9]" | grep -v '"' | sed -n 1p | awk '{print $4}' | sed 's/;//g')
	git pull
	eval /tmp/bootstrap.sh
	xcodebuild -configuration Debug
	xcodebuild -configuration Release
	cd build/Release && zip -qry -FS "DiskArbitrationFixup-$version-RELEASE.zip" * || exit 1
	cd ../../build/Debug && zip -qry -FS "DiskArbitrationFixup-$version-DEBUG.zip" * || exit 1
	cd ../..
	mv build/Debug/*.zip ~/Downloads/自编译Kexts/
	mv build/Release/*.zip ~/Downloads/自编译Kexts/
	
#	## NightShiftUnlocker
#	cd ~
#	if [[ ! -d "NightShiftUnlocker" ]] ; then
#		echo -e "\033[41;33m NightShiftUnlocker 不存在，开始下载... \033[0m"
#		git clone https://github.com/0xFireWolf/NightShiftUnlocker
#	fi
#	echo -e "\033[41;33m 开始编译 NightShiftUnlocker ... \033[0m"
#	sleep 3
#	cd ~/NightShiftUnlocker && rm -rf Lilu.kext
#	version=$(grep -rn MODULE_VERSION NightShiftUnlocker.xcodeproj/project.pbxproj | grep "[0-9]" | grep -v '"' | sed -n 1p | awk '{print $4}' | sed 's/;//g')
#	git pull
#	eval /tmp/bootstrap.sh
#	xcodebuild -configuration Debug
#	xcodebuild -configuration Release
#	cd build/Release && zip -qry -FS "NightShiftUnlocker-$version-RELEASE.zip" * || exit 1
#	cd ../../build/Debug && zip -qry -FS "NightShiftUnlocker-$version-DEBUG.zip" * || exit 1
#	cd ../..
#	mv build/Debug/*.zip ~/Downloads/自编译Kexts/
#	mv build/Release/*.zip ~/Downloads/自编译Kexts/
#	git checkout .
	
	## NoTouchID
	cd ~
	if [[ ! -d "NoTouchID" ]] ; then
		echo -e "\033[41;33m NoTouchID 不存在，开始下载... \033[0m"
		git clone https://github.com/al3xtjames/NoTouchID
	fi
	echo -e "\033[41;33m 开始编译 NoTouchID ... \033[0m"
	sleep 3
	cd ~/NoTouchID && rm -rf Lilu.kext
	git pull
	eval /tmp/bootstrap.sh
	xcodebuild -configuration Debug
	xcodebuild -configuration Release
	mv build/Debug/*.zip ~/Downloads/自编译Kexts/
	mv build/Release/*.zip ~/Downloads/自编译Kexts/
	
	## SystemProfilerMemoryFixup
	cd ~
	if [[ ! -d "SystemProfilerMemoryFixup" ]] ; then
		echo -e "\033[41;33m SystemProfilerMemoryFixup 不存在，开始下载... \033[0m"
		git clone https://github.com/Goldfish64/SystemProfilerMemoryFixup
	fi
	echo -e "\033[41;33m 开始编译 SystemProfilerMemoryFixup ... \033[0m"
	sleep 3
	cd ~/SystemProfilerMemoryFixup && rm -rf Lilu.kext
	version=$(grep -rn MODULE_VERSION SystemProfilerMemoryFixup.xcodeproj/project.pbxproj | grep "[0-9]" | grep -v '"' | sed -n 1p | awk '{print $4}' | sed 's/;//g')
	git pull
	eval /tmp/bootstrap.sh
	xcodebuild -configuration Debug
	xcodebuild -configuration Release
	cd build/Release && zip -qry -FS "SystemProfilerMemoryFixup-$version-RELEASE.zip" * || exit 1
	cd ../../build/Debug && zip -qry -FS "SystemProfilerMemoryFixup-$version-DEBUG.zip" * || exit 1
	cd ../..
	mv build/Debug/*.zip ~/Downloads/自编译Kexts/
	mv build/Release/*.zip ~/Downloads/自编译Kexts/
	
	## ThunderboltReset
	cd ~
	if [[ ! -d "ThunderboltReset" ]] ; then
		echo -e "\033[41;33m ThunderboltReset 不存在，开始下载... \033[0m"
		git clone https://github.com/osy86/ThunderboltReset
	fi
	echo -e "\033[41;33m 开始编译 ThunderboltReset ... \033[0m"
	sleep 3
	cd ~/ThunderboltReset && rm -rf Lilu.kext
	version=$(grep -rn MODULE_VERSION ThunderboltReset.xcodeproj/project.pbxproj | grep "[0-9]" | grep -v '"' | sed -n 1p | awk '{print $4}' | sed 's/;//g')
	git pull
	eval /tmp/bootstrap.sh
	xcodebuild -configuration Debug
	xcodebuild -configuration Release
	cd build/Release && zip -qry -FS "ThunderboltReset-$version-RELEASE.zip" * || exit 1
	cd ../../build/Debug && zip -qry -FS "ThunderboltReset-$version-DEBUG.zip" * || exit 1
	cd ../..
	mv build/Debug/*.zip ~/Downloads/自编译Kexts/
	mv build/Release/*.zip ~/Downloads/自编译Kexts/
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
