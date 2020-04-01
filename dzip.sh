#!/bin/bash

main(){
	zip - "$1" | gsplit -b 4095m -d -a 3 "$1" "$1."
}

main "$@"
