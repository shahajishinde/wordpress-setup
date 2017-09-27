#!/bin/bash
wplog=wordpress.log
mysqllog=mysql.log
nginxlog=nginx.log
installlog=installation.log
#installation check
installation_check(){
	echo "Checking Installation of $1..."
	dpkg --status $1 >> /dev/null
	if [ $? -ne 0 ]
	then
		echo "Installing $1..."
		sudo apt-get install $1 -y &>> $installlog 
		if [ $? -eq 0 ]
		then
			echo "Successfully Installed $1..."
		else
			echo "Error while installing $1. Exiting..."
			exit 1
		fi
	else
		echo "$1 is already installed..."
	fi	
}

#domain name entry 
get_domain_name(){
	read -p "Enter Domain Name: " domain
	echo "127.0.0.1         $domain" | sudo tee -a  /etc/hosts &>> $wplog
	if [ $? -eq 0 ]
	then
		echo "Domain name entry successful"
	else
		echo "Error occured while creating domain name entry"
		exit 1
	fi
}

#setting up nginx config file for the site
set_nginx_file(){
	echo "Setting up nginx config file for your site..."
	sudo cp nginx.conf /etc/nginx/sites-available/$domain
	sudo sed -i "s/domain_name/$domain/g" /etc/nginx/sites-available/$domain
	sudo ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/

	if [ $? -eq 0 ]
	then	
		echo "Successfully set up nginx config file"
		sudo systemctl reload nginx &>> $nginxlog
	else
		echo "Some error occured during nginx configuration"
		exit 1
	fi
}


#Download Wordpress 
wordpress_download(){
	echo "Downloading Wordpress..."
	sudo wget -O wordpress.zip http://wordpress.org/latest.zip &>> $wplog
	installation_check unzip
	sudo unzip -q wordpress.zip &>> $wplog
	sudo rm -f wordpress.zip
	sudo mkdir /var/www/$domain
	sudo mv wordpress/* /var/www/$domain
	sudo rm -rf wordpress	
	echo "Successfully downloaded Wordpress"
}

#MySQL installation
mysql_installation(){
	#storing temporary root password for mysql
	sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password password" &>> $mysqllog
	sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password password" &>> $mysqllog
	installation_check mysql-server
	#erasing the saved password
	sudo debconf-communicate mysql-server <<< 'PURGE' &>> $mysqllog
}

#Create site default database 
mysql_create_db(){
	echo "Creating database for your site..."
	db_ext="_db"
	db_name=${domain//./_}$db_ext
	mysql -u root -ppassword -e "create database $db_name;" &>> $mysqllog
	echo "Database Created"
}

#Setting Up wp-config.php
wpconfig_setup(){
	echo "Setting up the wp-config.php file..."
	sudo cp wp-config.php /var/www/$domain/
	sudo sed -i "s/database_name_here/$db_name/g" /var/www/$domain/wp-config.php
	sudo sed -i "s/username_here/root/g" /var/www/$domain/wp-config.php
	sudo sed -i "s/password_here/password/g" /var/www/$domain/wp-config.php
	echo "Done setting up wp-config.php file"
}

#update package-list 
echo "Updating system. This may take time..."
sudo apt-get update &>> $installlog


installation_check php7.0-fpm
installation_check php-mysql
installation_check nginx
mysql_installation
get_domain_name
set_nginx_file
wordpress_download
mysql_create_db
wpconfig_setup

mkdir logs
mv *.log logs/
echo "Database username: root"
echo "Database password: password"
echo "Open your site "$domain" in the browser"
