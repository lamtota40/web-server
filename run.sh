#!/bin/bash

sudo apt update
sudo apt install -y apache2 php php-curl libapache2-mod-php php-mysql mysql-server

pass="Abcd1234!"
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $pass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $pass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $pass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin

sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo a2enmod rewrite

sudo mysql <<EOF
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'Abcd1234!';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT
EOF

#sudo mysql_secure_installation
apt install -y vsftpd
cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
sed -i 's/#\s*write_enable=YES/write_enable=YES/' /etc/vsftpd.conf
sed -i 's/#\s*chroot_local_user=YES/chroot_local_user=YES/' /etc/vsftpd.conf
echo "allow_writeable_chroot=YES" | tee -a /etc/vsftpd.conf

sudo systemctl daemon-reload
sudo systemctl enable apache2
sudo systemctl enable mysql
sudo systemctl restart apache2
sudo systemctl restart mysql

systemctl restart vsftpd
systemctl enable vsftpd
