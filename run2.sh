#!/bin/bash

# Update dan install webserver stack
sudo apt update
sudo apt install apache2 php php-curl php-mbstring php-zip php-gd php-json php-mysql libapache2-mod-php mysql-server -y

# Setup phpMyAdmin
cd /usr/share/
sudo wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz
sudo tar -xvzf phpMyAdmin-5.2.1-all-languages.tar.gz
sudo mv phpMyAdmin-5.2.1-all-languages phpmyadmin
cp phpmyadmin/config.sample.inc.php phpmyadmin/config.inc.php
rm -rf phpMyAdmin-5.2.1-all-languages.tar.gz
sudo nano phpmyadmin/config.inc.php
cd

$cfg['blowfish_secret'] = 'g45hfS5jghG#lkj34lklkj3345jkfsd'; // minimal 32 karakter acak

sudo chown -R www-data:www-data /usr/share/phpmyadmin
# Atur permission dasar folder web
sudo chown -R root:www-data /var/www/html
sudo chmod -R 775 /var/www/html
sudo chmod g+s /var/www/html
sudo a2enmod rewrite

sudo phpenmod mbstring

sudo systemctl daemon-reload
sudo systemctl enable apache2
sudo systemctl enable mysql
sudo systemctl restart apache2
sudo systemctl restart mysql

# Buat user MySQL admin
sudo mysql <<EOF
CREATE USER 'admin'@'localhost' IDENTIFIED BY '$pass';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT
EOF

# Aktifkan service Apache dan MySQL
sudo systemctl daemon-reload
sudo systemctl enable apache2
sudo systemctl enable mysql
sudo systemctl restart apache2
sudo systemctl restart mysql

# Buat user SFTP "web" tanpa akses shell
useradd -m -s /usr/sbin/nologin web
echo "web:$pass" | chpasswd
usermod -aG www-data web

# Buat direktori chroot
mkdir -p /home/web/html
chown root:root /home/web
chmod 755 /home/web

# Bind mount /var/www/html ke /home/web/html
mount --bind /var/www/html /home/web/html

# Tambahkan fstab entry agar bind mount persist setelah reboot
if ! grep -q "/home/web/html" /etc/fstab; then
  echo "/var/www/html /home/web/html none bind 0 0" >> /etc/fstab
fi

# Tambahkan konfigurasi SFTP chroot jika belum ada
if ! grep -q "Match User web" /etc/ssh/sshd_config; then
cat <<EOF >> /etc/ssh/sshd_config

Match User web
  ChrootDirectory /home/web
  ForceCommand internal-sftp
  AllowTcpForwarding no
  X11Forwarding no
EOF
fi

# Restart SSH
systemctl restart ssh


read -p "Masukkan domain kamu (contoh: example.com): " domain
email="admin@$domain"

# Pasang HTTPS
sudo apt install -y cron certbot python3-certbot-apache
sudo certbot --apache --non-interactive --agree-tos --redirect -m "$email" -d "$domain" -d "www.$domain"
sudo systemctl restart apache2

php -v


















# Setup phpMyAdmin dengan password otomatis
pass="Abcd1234!"
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $pass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $pass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $pass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin

# Atur permission dasar folder web
sudo chown -R root:www-data /var/www/html
sudo chmod -R 775 /var/www/html
sudo chmod g+s /var/www/html
sudo a2enmod rewrite

# Buat user MySQL admin
sudo mysql <<EOF
CREATE USER 'admin'@'localhost' IDENTIFIED BY '$pass';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT
EOF

# Aktifkan service Apache dan MySQL
sudo systemctl daemon-reload
sudo systemctl enable apache2
sudo systemctl enable mysql
sudo systemctl restart apache2
sudo systemctl restart mysql

# Buat user SFTP "web" tanpa akses shell
useradd -m -s /usr/sbin/nologin web
echo "web:$pass" | chpasswd
usermod -aG www-data web

# Buat direktori chroot
mkdir -p /home/web/html
chown root:root /home/web
chmod 755 /home/web

# Bind mount /var/www/html ke /home/web/html
mount --bind /var/www/html /home/web/html

# Tambahkan fstab entry agar bind mount persist setelah reboot
if ! grep -q "/home/web/html" /etc/fstab; then
  echo "/var/www/html /home/web/html none bind 0 0" >> /etc/fstab
fi

# Tambahkan konfigurasi SFTP chroot jika belum ada
if ! grep -q "Match User web" /etc/ssh/sshd_config; then
cat <<EOF >> /etc/ssh/sshd_config

Match User web
  ChrootDirectory /home/web
  ForceCommand internal-sftp
  AllowTcpForwarding no
  X11Forwarding no
EOF
fi

# Restart SSH
systemctl restart ssh


read -p "Masukkan domain kamu (contoh: example.com): " domain
email="admin@$domain"

# Pasang HTTPS
sudo apt install -y cron certbot python3-certbot-apache
sudo certbot --apache --non-interactive --agree-tos --redirect -m "$email" -d "$domain" -d "www.$domain"
sudo systemctl restart apache2

sudo mv /usr/share/phpmyadmin /usr/share/phpmyadmin-old
cp /usr/share/phpmyadmin-old/config.sample.inc.php /usr/share/phpmyadmin-old/config.inc.php
