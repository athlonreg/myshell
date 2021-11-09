#!/bin/bash
#
#**********************************************************
#@Author: 		套陆
#@Date:			2020-2-26
#@FileName:		autobattery.sh
#@Email: 		15563836030@163.com
#@Site: 		https://blog.cloudops.ml/
#@Copyright (C): 	2020 All rights reserved
#@Description:		Auto generate hotpatch for battery
#**********************************************************
#

## Build base BAT0 SSDT struct
base(){
	cat > ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl << EOF
// battery for ${brand}-${model}
DefinitionBlock ("", "SSDT", 2, "OCLT", "BAT0", 0)
{
	//External Block
	External (_SB.PCI0.${lpcbName}.${ecName}, DeviceObj)
	
	// B1B2 Block
	Method (B1B2, 2, NotSerialized)
	{
		Local0 = (Arg1 << 0x08)
		Local0 |= Arg0
		Return (Local0)
	}

	// B1B4 Block
	Method (B1B4, 4, NotSerialized)
	{
		Local0 = Arg3
		Local0 = (Arg2 | (Local0 << 0x08))
		Local0 = (Arg1 | (Local0 << 0x08))
		Local0 = (Arg0 | (Local0 << 0x08))
		Return (Local0)
	}
	
	// RE1B Block
	Method (RE1B, 1, NotSerialized)
	{
		OperationRegion (ERM2, EmbeddedControl, Arg0, One)
		Field (ERM2, ByteAcc, NoLock, Preserve)
		{
			BYTE,   8
		}

		Return (BYTE)
	}

	// RECB Block
	Method (RECB, 2, Serialized)
	{
		Arg1 >>= 0x03
		Name (TEMP, Buffer (Arg1){})
		Arg1 += Arg0
		Local0 = Zero
		While ((Arg0 < Arg1))
		{
			TEMP [Local0] = RE1B (Arg0)
			Arg0++
			Local0++
		}

		Return (TEMP)
	}

	// WE1B Block
	Method (WE1B, 2, NotSerialized)
	{
		OperationRegion (ERM2, EmbeddedControl, Arg0, One)
		Field (ERM2, ByteAcc, NoLock, Preserve)
		{
			BYTE,   8
		}

		BYTE = Arg1
	}

	// WECB Block
	Method (WECB, 3, Serialized)
	{
		Arg1 = ((Arg1 + 0x07) >> 0x03)
		Name (TEMP, Buffer (Arg1){})
		TEMP = Arg2
		Arg1 += Arg0
		Local0 = Zero
		While ((Arg0 < Arg1))
		{
			WE1B (Arg0, DerefOf (TEMP [Local0]))
			Arg0++
			Local0++
		}
	}
	
	// EC Block
	Scope (\_SB.PCI0.${lpcbName}.${ecName})
	{
		// OperationRegion and Field Block
	}
}
EOF

## handle B1B2
if [[ ${exsitB1B2} -ne 1 ]] ; then
	B1B2Num=$(grep -n 'B1B2 Block' ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl | cut -d ':' -f 1)
	sed -i "" "${B1B2Num},$((${B1B2Num}+7))d" ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl
fi

## handle B1B4
if [[ ${exsitB1B4} -ne 1 ]] ; then
	B1B4Num=$(grep -n 'B1B4 Block' ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl | cut -d ':' -f 1)
	sed -i "" "${B1B4Num},$((${B1B4Num}+9))d" ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl
fi

## handle RECB RE1B
if [[ ${exsitRecb} -ne 1 ]] ; then
	RE1BNum=$(grep -n 'RE1B Block' ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl | cut -d ':' -f 1)
	sed -i "" "${RE1BNum},$((${RE1BNum}+28))d" ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl
fi

## handle WECB WE1B
if [[ ${exsitWecb} -ne 1 ]] ; then
	WE1BNum=$(grep -n 'WE1B Block' ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl | cut -d ':' -f 1)
	sed -i "" "${WE1BNum},$((${WE1BNum}+27))d" ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl
fi

}

buildOrigin(){
	cd ${origindir}
	## Remove useless SSDTs
	rm -rf SSDT-x*
	
	## Remove all useless aml
	for i in $(ls | grep -v DSDT | grep -v SSDT)
	do
		rm -rf $i
	done
	
	## iasl all aml
	for i in $(ls *.aml)
	do
		iasl -da -dl $i 1>/dev/null 2>/dev/null
	done
	
	if [[ ! -f "DSDT.dsl" ]] ; then
		iasl DSDT.aml 1>/dev/null 2>/dev/null
	fi
}

printOpBlock(){
	cd ${origindir}
	opName=$(grep EmbeddedControl DSDT.dsl | awk -F '(' '{print $2}' | awk -F ',' '{print $1}')
	opNum=$(grep -n "Field (${opName}" DSDT.dsl | wc -l)
#	opAllColNum=$(grep -n "Field (ECOR" DSDT.dsl | wc -l)
	
	opFlag=1
	while [[ $opFlag -le $opNum ]]
	do
		## get the op block start column number
		opStartNum=$(grep -n "Field (${opName}" DSDT.dsl | cut -d: -f1 | sed -n ${opFlag}p)
		## get the op block end column number
		opEndNum=$(cat -n DSDT.dsl | sed -n $opStartNum,$(($opStartNum+1000))p | grep "}" | sed -n 1p | cut -f1)
		## First remove last 2 }
		sed -i "" '$d' ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl
		sed -i "" '$d' ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl
		## print OperationRegion
		if [[ "$opFlag" -eq "1" ]] ; then
			grep "OperationRegion (${opName}" DSDT.dsl >> ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl
		fi
		
		## get the op block
		sed -n $opStartNum,$(($opEndNum))p DSDT.dsl > tmp.txt
		sed -i "" "/BYTE,   8/d" tmp.txt
		num=$(cat tmp.txt | wc -l)
		fieldArryIndex=0
		for((i=1;i<=$num;i++))
		do
			flag=$(sed -n ${i}p tmp.txt | awk '/[A-Z]{3,4},...[0-9]{1,3}/' | wc -l)
			if [[ "$flag" -eq "1" ]] ; then
				field=$(sed -n ${i}p tmp.txt | sed 's/ //g' | cut -d, -f1)
				fieldnum=$(sed -n ${i}p tmp.txt | sed 's/ //g' | cut -d, -f2)
				if [[ "$fieldnum" -eq "16" ]] ; then
					fieldOcurNum=$(grep "${field}" DSDT.dsl | grep -v "${field},   ${fieldnum}" | wc -l)
					if [[ "$fieldnum" -ne "1" ]] ; then
						fieldArray[${fieldArryIndex}]=$field
						sed -i "" "s/${field},   ${fieldnum}/${field:1:4}0,8,${field:1:4}1,8,\/\/ ${field}   ${fieldnum}/" tmp.txt
						((fieldArryIndex++))
					fi
				elif [[ "$fieldnum" -eq "32" ]] ; then
					fieldOcurNum=$(grep "${field}" DSDT.dsl | grep -v "${field},   ${fieldnum}" | wc -l)
					if [[ "$fieldnum" -ne "1" ]] ; then
						fieldArray[${fieldArryIndex}]=$field
						sed -i "" "s/${field},   ${fieldnum}/${field:1:4}0,8,${field:1:4}1,8,${field:1:4}2,8,${field:1:4}3,8,\/\/ ${field}   ${fieldnum}/" tmp.txt
						((fieldArryIndex++))
					fi
				elif [[ "$fieldnum" -le "8" ]] ; then
					sed -i "" "s/${field},   ${fieldnum}/,   ${fieldnum}/" tmp.txt
				else
					sed -i "" "s/${field},   ${fieldnum}/\/\/${field},   ${fieldnum}/" tmp.txt
				fi
			fi
		done
		sed -n '1,$p' tmp.txt >> ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl
		## Add last 2 } after add op Field
		echo -e '\t}' >> ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl
		echo "}" >> ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl
		((opFlag++))
#		tmpColNum=$(grep -n 'Field (ECOR' DSDT.dsl | awk -F ':' '{print $1}' | sed -n ${opFlag}p)
#		latestOpBlockColNum=$(cat -n DSDT.dsl | sed -n ${tmpColNum},$((${tmpColNum}+400))p | grep '}' | sed -n 1p | awk '{print $1}')
#		latestOpBlock=$(sed -n ${tmpColNum},${latestOpBlockColNum}p DSDT.dsl)
#		((opFlag++))
#		opBlockColNum=$(cat -n ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl | grep 'Op Block' | awk '{print $1}')
#		gsed -i '"${opBlockColNum}"a "${latestOpBlock}"' ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl
	done
	
	## replace OperationRegion field with ERAM
	sed -i "" "s/${opName}/ERAM/g" ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl
	
#	awk '/[A-Z]{3,4},...[0-9]{1,3}|Offset/' ~/Desktop/SSDT-OCBAT0-${brand}-${model}.dsl
	
}

getEcName(){
	cd ${origindir}
	ecName=$(grep PNP0C09 -B 3 DSDT.dsl | grep Device | grep EC | awk -F '(' '{print $2}' | awk -F ')' '{print $1}')
}

getBatPath(){
	tmpPath=$(grep "Device (BAT0)" DSDT.dsl -B 2000 | grep -E "Scope \(\\_SB\)|Device \(EC\)|Device \(H_EC\)|Device \(EC0\)" | sed -n p | awk -F '(' '{print $2}' | awk -F ')' '{print $1}')
	if [[ ${tmpPath} == "EC" || ${tmpPath} == "EC0" || ${tmpPath} == "H_EC" ]] ; then
		batPath="\_SB.PCI0.${lpcbName}.${tmpPath}"
	else
		batPath="\_SB"
	fi
}

getLpcbName(){
	cd ${origindir}
	lpcbName=$(grep "Device (LPC" DSDT.dsl | awk -F '(' '{print $2}' | awk -F ')' '{print $1}')
}

getLogicBatteryNum(){
	cd ${origindir}
	lbatteryNum=$(grep PNP0C0A -B 3 DSDT.dsl | grep "Device (BAT" | wc -l)
}

getPhisyclBatteryNum(){
	if [[ ${lbatteryNum} -eq 2 ]] ; then
		if [[ $(grep -n "Device (BAT1" -A 100 DSDT.dsl | grep "Method (_STA" -A 10 | grep "Return (0x00)" | wc -l) -eq 1 && $(grep -n "Device (BAT1" -A 100 DSDT.dsl | grep "Method (_STA" -A 10 | grep "Return (0x0F)" | wc -l) -eq 0 ]] ; then
			pbatteryNum=1
		else
			pbatteryNum=2
		fi
	fi
}

genNtfy(){
	cat > ~/Desktop/SSDT-NTFY.dsl << EOF
DefinitionBlock ("", "SSDT", 2, "OCLT", "NTFY", 0)
{
	External (\_SB.PCI0.LPCB.EC, DeviceObj)
	External (\_SB.PCI0.LPCB.EC.BATC, DeviceObj)

	Scope (\_SB.PCI0.LPCB.EC)
	{
		Method (_Q22, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
		{
			If (_OSI ("Darwin"))
			{
				CLPM ()
				If (HB0A)
				{
					Notify (BATC, 0x80) // Status Change
				}

				If (HB1A)
				{
					Notify (BATC, 0x80) // Status Change
				}
			}
			Else
			{
				\_SB.PCI0.LPCB.EC.XQ22 ()
			}
		}
		
		Method (_Q4A, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
		{
			If (_OSI ("Darwin"))
			{
				CLPM ()
				Notify (BATC, 0x81) // Information Change
			}
			Else
			{
				\_SB.PCI0.LPCB.EC.XQ4A ()
			}
		}
		
		Method (_Q4B, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
		{
			If (_OSI ("Darwin"))
			{
				CLPM ()
				Notify (BATC, 0x80) // Status Change
			}
			Else
			{
				\_SB.PCI0.LPCB.EC.XQ4B ()
			}
		}
		
		Method (_Q4C, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
		{
			If (_OSI ("Darwin"))
			{
				\_SB.PCI0.LPCB.EC.CLPM ()
				If (\_SB.PCI0.LPCB.EC.HB1A)
				{
					\_SB.PCI0.LPCB.EC.HKEY.MHKQ (0x4010)
					Notify (\_SB.PCI0.LPCB.EC.BATC, 0x01) // Device Check
				}
				Else
				{
					\_SB.PCI0.LPCB.EC.HKEY.MHKQ (0x4011)
					If (\_SB.PCI0.LPCB.EC.BAT1.XB1S)
					{
						Notify (\_SB.PCI0.LPCB.EC.BATC, 0x03) // Eject Request
					}
				}
			}
			Else
			{
				\_SB.PCI0.LPCB.EC.XQ4C ()
			}
		}
			
		Method (_Q4D, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
		{
			If (_OSI ("Darwin"))
			{
				CLPM ()
				If (\BT2T)
				{
					If ((^BAT1.SBLI == 0x01))
					{
						Sleep (0x0A)
						If ((HB1A && (SLUL == 0x00)))
						{
							^BAT1.XB1S = 0x01
							Notify (\_SB.PCI0.LPCB.EC.BATC, 0x01) // Device Check
						}
					}
					ElseIf ((SLUL == 0x01))
					{
						^BAT1.XB1S = 0x00
						Notify (\_SB.PCI0.LPCB.EC.BATC, 0x03) // Eject Request
					}
				}

				If ((^BAT1.B1ST & ^BAT1.XB1S))
				{
					Notify (BATC, 0x80) // Status Change
				}
			}
			Else
			{
				\_SB.PCI0.LPCB.EC.XQ4D ()
			}
		}
		
		Method (_Q24, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
		{
			If (_OSI ("Darwin"))
			{
				CLPM ()
				Notify (BATC, 0x80) // Status Change
			}
			Else
			{
				\_SB.PCI0.LPCB.EC.XQ24 ()
			}
		}
			
		Method (_Q25, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
		{
			If (_OSI ("Darwin"))
			{
				If ((^BAT1.B1ST & ^BAT1.XB1S))
				{
					CLPM ()
					Notify (BATC, 0x80) // Status Change
				}
			}
			Else
			{
				\_SB.PCI0.LPCB.EC.XQ25 ()
			}
		}
			
		Method (BFCC, 0, NotSerialized)
		{
			If (_OSI ("Darwin"))
			{
				If (\_SB.PCI0.LPCB.EC.BAT0.B0ST)
				{
					Notify (BATC, 0x81) // Information Change
				}

				If (\_SB.PCI0.LPCB.EC.BAT1.B1ST)
				{
					Notify (BATC, 0x81) // Information Change
				}
			}
			Else
			{
				\_SB.PCI0.LPCB.EC.XFCC ()
			}
		}
		
		Method (BATW, 1, NotSerialized)
		{
			If (_OSI ("Darwin"))
			{
				If (\BT2T)
				{
					Local0 = \_SB.PCI0.LPCB.EC.BAT1.XB1S
					If ((HB1A && !SLUL))
					{
						Local1 = 0x01
					}
					Else
					{
						Local1 = 0x00
					}

					If ((Local0 ^ Local1))
					{
						\_SB.PCI0.LPCB.EC.BAT1.XB1S = Local1
						Notify (\_SB.PCI0.LPCB.EC.BATC, 0x01) // Device Check
					}
				}
			}
			Else
			{
				\_SB.PCI0.LPCB.EC.XATW (Arg0)
			}
		}
	}
}
EOF
}

handleNotify(){
	cd ${origindir}
	for i in $(grep -n 'Notify (*.BAT' DSDT.dsl | awk -F ':' '{print $1}')
	do
		ntfyCurColNum=$i
		ntfyMethodIndex=0
		ntfyMethodArray[${ntfyMethodIndex}]=$(sed -n $((${ntfyCurColNum}-50)),${ntfyCurColNum}p DSDT.dsl | grep Method | awk 'END{print}' | awk '{print $2}' | sed 's/(//g' | sed 's/,//g')
	done
}

genBatc(){
	cat > ~/Desktop/SSDT-OCBATC.dsl << EOF
DefinitionBlock ("", "SSDT", 2, "OCLT", "BATC", 0)
{
	External (_SB.PCI0.LPCB.EC, DeviceObj)
	External (_SB.PCI0.LPCB.EC.BAT0._BIF, MethodObj)
	External (_SB.PCI0.LPCB.EC.BAT0._BST, MethodObj)
	External (_SB.PCI0.LPCB.EC.BAT0._HID, IntObj)
	External (_SB.PCI0.LPCB.EC.BAT0._STA, MethodObj)
	External (_SB.PCI0.LPCB.EC.BAT1, DeviceObj)
	External (_SB.PCI0.LPCB.EC.BAT1._BIF, MethodObj)
	External (_SB.PCI0.LPCB.EC.BAT1._BST, MethodObj)
	External (_SB.PCI0.LPCB.EC.BAT1._HID, IntObj)
	External (_SB.PCI0.LPCB.EC.BAT1._STA, MethodObj)

	Scope (\_SB.PCI0.LPCB.EC)
	{
		Device (BATC)
		{
			Name (_HID, EisaId ("PNP0C0A"))
			Name (_UID, 0x02)
			Method (_INI, 0, NotSerialized)
			{
				If (_OSI ("Darwin"))
				{
					^^BAT0._HID = Zero
					^^BAT1._HID = Zero
				}
			}

			Method (CVWA, 3, NotSerialized)
			{
				If (Arg2)
				{
					Arg0 = ((Arg0 * 0x03E8) / Arg1)
				}

				Return (Arg0)
			}

			Method (_STA, 0, NotSerialized)
			{
				If (_OSI ("Darwin"))
				{
					Return ((^^BAT0._STA () | ^^BAT1._STA ()))
				}
				Else
				{
					Return (0)
				}
			}

			Name (B0CO, Zero)
			Name (B1CO, Zero)
			Name (B0DV, Zero)
			Name (B1DV, Zero)
			Method (_BST, 0, NotSerialized)
			{
				Local0 = ^^BAT0._BST ()
				Local2 = ^^BAT0._STA ()
				If ((0x1F == Local2))
				{
					Local4 = DerefOf (Local0 [0x02])
					If ((!Local4 || (Ones == Local4)))
					{
						Local2 = Zero
					}
				}

				Local1 = ^^BAT1._BST ()
				Local3 = ^^BAT1._STA ()
				If ((0x1F == Local3))
				{
					Local4 = DerefOf (Local1 [0x02])
					If ((!Local4 || (Ones == Local4)))
					{
						Local3 = Zero
					}
				}

				If (((0x1F != Local2) && (0x1F == Local3)))
				{
					Local0 = Local1
					Local2 = Local3
					Local3 = Zero
				}

				If (((0x1F == Local2) && (0x1F == Local3)))
				{
					Local4 = DerefOf (Local0 [Zero])
					Local5 = DerefOf (Local1 [Zero])
					If (((Local4 == 0x02) || (Local5 == 0x02)))
					{
						Local0 [Zero] = 0x02
					}
					ElseIf (((Local4 == One) || (Local5 == One)))
					{
						Local0 [Zero] = One
					}
					ElseIf (((Local4 == 0x05) || (Local5 == 0x05)))
					{
						Local0 [Zero] = 0x05
					}
					ElseIf (((Local4 == 0x04) || (Local5 == 0x04)))
					{
						Local0 [Zero] = 0x04
					}

					Local0 [One] = (CVWA (DerefOf (Local0 [One]), B0DV, 
						B0CO) + CVWA (DerefOf (Local1 [One]), B1DV, B1CO))
					Local0 [0x02] = (CVWA (DerefOf (Local0 [0x02]), B0DV, 
						B0CO) + CVWA (DerefOf (Local1 [0x02]), B1DV, B1CO))
					Local0 [0x03] = ((DerefOf (Local0 [0x03]) + DerefOf (
						Local1 [0x03])) / 0x02)
				}

				Return (Local0)
			}

			Method (_BIF, 0, NotSerialized)
			{
				Local0 = ^^BAT0._BIF ()
				Local2 = ^^BAT0._STA ()
				If ((0x1F == Local2))
				{
					Local4 = DerefOf (Local0 [One])
					If ((!Local4 || (Ones == Local4)))
					{
						Local2 = Zero
					}

					Local4 = DerefOf (Local0 [0x02])
					If ((!Local4 || (Ones == Local4)))
					{
						Local2 = Zero
					}

					Local4 = DerefOf (Local0 [0x04])
					If ((!Local4 || (Ones == Local4)))
					{
						Local2 = Zero
					}
				}

				Local1 = ^^BAT1._BIF ()
				Local3 = ^^BAT1._STA ()
				If ((0x1F == Local3))
				{
					Local4 = DerefOf (Local1 [One])
					If ((!Local4 || (Ones == Local4)))
					{
						Local3 = Zero
					}

					Local4 = DerefOf (Local1 [0x02])
					If ((!Local4 || (Ones == Local4)))
					{
						Local3 = Zero
					}

					Local4 = DerefOf (Local1 [0x04])
					If ((!Local4 || (Ones == Local4)))
					{
						Local3 = Zero
					}
				}

				If (((0x1F != Local2) && (0x1F == Local3)))
				{
					Local0 = Local1
					Local2 = Local3
					Local3 = Zero
				}

				If (((0x1F == Local2) && (0x1F == Local3)))
				{
					B0CO = !DerefOf (Local0 [Zero])
					B1CO = !DerefOf (Local1 [Zero])
					Local0 [Zero] = One
					B0DV = DerefOf (Local0 [0x04])
					B1DV = DerefOf (Local1 [0x04])
					Local0 [One] = (CVWA (DerefOf (Local0 [One]), B0DV, 
						B0CO) + CVWA (DerefOf (Local1 [One]), B1DV, B1CO))
					Local0 [0x02] = (CVWA (DerefOf (Local0 [0x02]), B0DV, 
						B0CO) + CVWA (DerefOf (Local1 [0x02]), B1DV, B1CO))
					Local0 [0x04] = ((B0DV + B1DV) / 0x02)
					Local0 [0x05] = (CVWA (DerefOf (Local0 [0x05]), B0DV, 
						B0CO) + CVWA (DerefOf (Local1 [0x05]), B1DV, B1CO))
					Local0 [0x06] = (CVWA (DerefOf (Local0 [0x06]), B0DV, 
						B0CO) + CVWA (DerefOf (Local1 [0x06]), B1DV, B1CO))
				}

				Return (Local0)
			}
		}
	}
}
EOF
}

getFieldUnitObj(){
	cd ${origindir}
	grep EmbeddedControl
}

printHelp(){
	echo -n "
Usage:
	-b 品牌
	-m 机器型号
	-o 原始ACPI路径
	-n 逻辑电池数
	-p 物理电池数
	-e EC设备名称
	-l LPCB设备名称
	-t 存在B1B2(存在要拆分的16位字段)
	-f 存在B1B4 (存在要拆分的32位字段)
	-r 存在RECB(存在大于64位的字段读操作)
	-w 存在WECB(存在大于64位的字段写操作)
	"
	exit 1
}

getParam(){
	while getopts ":b:m:o:n:p:e:l:tfrw" options
	do
		case $options in
			b)
				brand=${OPTARG}
#				echo $brand
				;;
			m)
				model=${OPTARG}
#				echo $model
				;;
			o)
				origindir="${OPTARG}"
#				echo "$origindir"
				;;
			n)
				lbatteryNum=${OPTARG}
#				echo $lbatteryNum
				;;
			p)
				pbatteryNum=${OPTARG}
#				echo $pbatteryNum
				exit
				;;
			e)
				ecName=${OPTARG}
#				echo $ecName
				;;
			l)
				lpcbName=${OPTARG}
#				echo $lpcbName
				;;
			t)
				exsitB1B2=1
#				echo $exsitB1B2
				;;
			f)
				exsitB1B4=1
#				echo $exsitB1B4
				;;
			r)
				exsitRecb=1
#				echo $exsitRecb
				;;
			w)
				exsitWecb=1
#				echo $exsitWecb
				;;
			:)
				printHelp
				;;
			?)
				printHelp
				;;
		esac
	done
}

main(){
	## Define and init all variables
	ecName=""
	lpcbName="LPCB"
	pbatteryNum=1
	lbatteryNum=1
	exsitB1B2=0
	exsitB1B4=0
	exsitRecb=0
	exsitWecb=0
	
	getParam "$@"
	buildOrigin
	
	## Get all use properties name and path
	getEcName
	getLpcbName
	getBatPath
	getLogicBatteryNum
	getPhisyclBatteryNum
	base
	printOpBlock

	if [[ ${lbatteryNum} -eq 2 ]] ; then
		genBatc
	fi
	if [[ ${pbatteryNum} -eq 2 ]] ; then
		genNtfy
	fi
}

main "$@"

exit 0
