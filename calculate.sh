############################################################
#                   Created by Canvas                      #
#                    Author: Canvas                        #
#             Site: https://blog.iamzhl.top/               #
#               Email: 1143991340@qq.com                   #
############################################################

#!/bin/bash 

# variable 
read -t 30 -p "Input the varible1: " num1
read -t 30 -p "Input the varible2: " num2
read -t 30 -p "Input the oper(+ - * / % ^): " oper

if [[ -n "$num1" && -n "$num2" && -n "$oper" ]] ; then 
	test1=$(echo $num1 | sed 's/[0-9]//g') 
	test2=$(echo $num2 | sed 's/[0-9]//g')
	
	if [[ -n "$test1" || -n "$test2" ]] ; then 
		echo "操作数不能为空" 
		exit 11 
	else
		if [[ "$oper" == "+" ]] ; then 
			echo "$num1 $oper $num2 = $(($num1 + $num2))"
		elif [[ "$oper" == "-" ]] ; then 
			echo "$num1 $oper $num2 = $(($num1 - $num2))"
		elif [[ "$oper" == "*" ]] ; then
	                echo "$num1 $oper $num2 = $(($num1 * $num2))"
		elif [[ "$oper" == "/" ]] ; then
	                echo "$num1 $oper $num2 = $(($num1 / $num2))"
		elif [[ "$oper" == "%" ]] ; then
	                echo "$num1 $oper $num2 = $(($num1 % $num2))"
		elif [[ "$oper" == "^" ]] ; then
                	echo "$num1 $oper $num2 = $(($num1 ** $num2))"
		else 
			echo "运算符不合法"
		fi
	fi
fi
