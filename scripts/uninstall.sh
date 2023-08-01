
#!/usr/bin/bash

## Remove everything above
clean(){
	rm -f  $HOME/.config/aliases/AnsiColt
	printf "\e[1;32m[OK]\e[m AnsiColt aliases were removed.\n"

	rm -rf $HOME/.ansible/collections/ansible_collections/MozeBaltyk/AnsiColt
	printf "\e[1;32m[OK]\e[m AnsiColt collection was uninstalled.\n"
}

clean
