sudo apt update -y
sudo apt install apache2 -y
sudo apt install php php-curl libapache2-mod-php -y
sudo apt install mysql-server -y
sudo apt install phpmyadmin -y

sudo mysql
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'Abcd1234$';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit


sudo systemctl status apache2
php -v
