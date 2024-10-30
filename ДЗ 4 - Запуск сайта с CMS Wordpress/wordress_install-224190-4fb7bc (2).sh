
apt install mysql-server-8.0
sudo apt install php-fpm php-curl php-mysqli php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip

sudo mysql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '1';
CREATE USER 'wordpress'@'%' IDENTIFIED WITH mysql_native_password BY '1';
grant all on wordpress.* to 'wordpress'@'%';

cd /tmp
curl -LO https://wordpress.org/latest.tar.gz
cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php
sudo cp -a /tmp/wordpress/. /var/www/wordpress
sudo chown -R www-data:www-data /var/www/wordpress
cd /var/www/wordpress/
nano wp-config.php


