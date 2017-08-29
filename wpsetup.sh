#!/bin/bash

#installation check
installation_check(){
	echo "Checking Installation of $1"
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

#Download Wordpress 
wordpress_download(){
	wget -O wordpress.zip http://wordpress.org/latest.zip
	unzip -q wordpress.zip
	rm -f wordpress.zip
	sudo mkdir /var/www/$domain
	sudo mv wordpress/* /var/www/$domain
	sudo rm -rf wordpress	
}

#MySQL installation

mysql_installation(){
	sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password password"
	sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password password"
	installation_check mysql-server
	sudo debconf-communicate mysql-server <<< 'PURGE'
}





