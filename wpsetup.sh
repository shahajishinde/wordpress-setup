#!/bin/sh

#installation check
installation_check(){
	echo "Checking Installed Packages"
	dpkg --status $1 >> /dev/null
	if [ $? -ne 0 ]
	then
		echo "Installing $1"
		sudo apt-get install $1
		if [ $? -e 0 ]
		then
			echo "Successfully Installed $1"
		else
			echo "Error while installing $1. Exiting..."
			exit 1
		fi
	else
		echo "$1 already installed"
	fi
	
}

#domain name entry 
get_domain_name(){
	read -p "Enter your desired domain name: " domain
	echo "127.0.0.1         $domain" | sudo tee -a  /etc/hosts
}

#setting up nginx config file for the site
set_nginx_file(){
	sudo cp nginx.conf /etc/nginx/sites-available/$domain
	sudo sed -i "s/domain_name/$domain/g" /etc/nginx/sites-available/$domain
	sudo ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
	sudo systemctl reload nginx 	
}


installation_check vim
get_domain_name


