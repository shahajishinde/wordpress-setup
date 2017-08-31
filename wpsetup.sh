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
	#storing temporary root password for mysql
	sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password password"
	sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password password"
	installation_check mysql-server
	#erasing the saved password
	sudo debconf-communicate mysql-server <<< 'PURGE'
}

#Create site default database 
mysql_create_db(){
	db_ext="_db"
	db_name={$domain//./_}$db_ext
	mysql -u root -p password -e "create database $db_name;"
}

#Setting Up wp-config.php
wpconfig-setup(){
	sudo cp wp-config.php /var/www/$domain/
	sudo sed -i "s/database_name_here/$db_name/g" /var/www/$domain/wp-config.php
	sudo sed -i "s/username_here/root/g" /var/www/$domain/wp-config.php
	sudo sed -i "s/password_here/password/g" /var/www/$domain/wp-config.php
}

installation_check php7.0-fpm
installation_check php-mysql
installation_check 


