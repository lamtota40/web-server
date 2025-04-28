sudo apt update -y
sudo apt install apache2 php php-curl libapache2-mod-php -y
sudo apt install mysql-server phpmyadmin -y

sudo mysql <<EOF
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'Abcd1234!';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT
EOF


sudo systemctl status apache2
php -v
