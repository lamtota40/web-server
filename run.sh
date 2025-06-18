#!/bin/bash

# Update dan install webserver stack
sudo apt update
sudo apt install -y apache2 php php-curl libapache2-mod-php php-mysql mysql-server

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

# Verifikasi dan informasi
ls -ld /var/www/html
groups web
echo "✅ SFTP user 'web' berhasil dibuat dan bisa write ke /var/www/html"
echo "📂 Folder: /home/web/html → bind mount ke /var/www/html"
echo "🔐 Gunakan di FileZilla/SFTP: user=web, pass=$pass"
