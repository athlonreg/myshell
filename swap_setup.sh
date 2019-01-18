############################################################
#                   Created by Canvas                      #
#                    Author: Canvas                        #
#             Site: https://blog.iamzhl.top/               #
#               Email: 15563836030@163.com                 #
############################################################

#!/bin/bash

# Setup swapfile
setswap(){
	echo "Starting setup swap partition......"
	read -p "Input size of swap partition you want to set(GB): " size
	((size=$size*1024))
	dd if=/dev/zero of=/mnt/swap bs=1M count=$size
	mkswap -f /mnt/swap
	chmod 0600 /mnt/swap
	swapon /mnt/swap
}

# Auto mount swap
automount(){
	echo -e "/mnt/swap none swap sw 0 0" >> /etc/fstab
}

# Optimize swap
optimize(){
	echo "Starting optimize for swap partition......"
	echo -e "vm.swappiness = 10" >> /etc/sysctl.conf
	echo -e "vm.vfs_cache_pressure = 50" >> /etc/sysctl.conf
	echo "Finished optimize for swap partition!"
}

over(){
	echo "Finished setup swap partition!"
	echo "Thanks for use!"
	free -hm
}

main(){
	setswap
	
	# auto mount start
	read -p "Setup swap partition to auto mount? (y / n)" option
	if [[ $option == "y" || $option == "yes" ]] ; then
		automount
	else
		echo "Don't set swap partition to auto mount!"
	fi
	# auto mount end
	
	# optimize start
	read -p "Setup optimize for swap partition? (y / n)" optim
	if [[ $optim == "y" || $optim == "yes" ]] ; then
		optimize
	else
		echo -e "Don't set optimize for swap partition!"
	fi
	# optimize end
	
	over
}

main

exit 0
