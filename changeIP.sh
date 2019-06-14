#!/bin/bash

srcIP=$1
dstIP=$2

sed -i "s/$srcIP/$dstIP/g" `grep -rl "$srcIP" /var/www/html/`
sed -i "s/$srcIP/$dstIP/g" `grep -rl "$srcIP" /usr/local/`
sed -i "s/$srcIP/$dstIP/g" `grep -rl "$srcIP" /etc/`

unset srcIP
unset dstIP
