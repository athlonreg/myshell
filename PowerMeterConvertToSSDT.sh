#!/bin/bash
# 功率表转换
# 原始数据格式如"8A060C00 01E201C7 08000020 3800007D 00080000"
# 将原始数据保存到文本文件中
# 将文本文件作为参数传进脚本执行即可
# 例如:
# PowerMeterConvertToSSDT.sh source.txt

if [[ $# -ne 1 ]] ; then
	echo "Usage:
	PowerMeterConvertToSSDT.sh [FILE]
Example:
	PowerMeterConvertToSSDT.sh source.txt"
	exit 1
fi
printf 'DefinitionBlock ("", "SSDT", 2, "CpuRef", "CpuPlug", 0x00003000)\n{\n\t%s\n}\n' "$(sed -E 's/ //g;s/.{16}/&\'$'\n\t/g;s/[0-9A-Fa-f]{2}/0x&,/g;s/,$//g' $1)"
