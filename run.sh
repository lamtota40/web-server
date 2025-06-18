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

sudo systemctl daemon-reload
sudo systemctl enable apache2
sudo systemctl enable mysql
sudo systemctl restart apache2
sudo systemctl restart mysql

# Buat user "web" tanpa akses shell
useradd -m -s /usr/sbin/nologin web
echo "web:Abcd1234!" | chpasswd
sudo usermod -aG www-data web
# Buat folder chroot & upload
mkdir -p /home/web/html

# Atur permission chroot
chown root:root /home/web
chmod 755 /home/web

# Pastikan folder target milik user
chown -R web:web /home/web/html

# Hapus isi folder html (kosongkan link jika sudah ada)
rm -rf /home/web/html

# Buat symlink ke /var/www/html
ln -s /var/www/html /home/web/html

# Atur pemilik direktori web (agar root punya akses penuh, grup untuk www-data)
sudo chown -R root:www-data /var/www/html

# Edit sshd_config jika belum ada config match
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

ls -ld /var/www/html
groups web
echo "✅ SFTP user 'web' berhasil dibuat."
echo "📂 Folder: /home/web/html → /var/www/html"
echo "🔐 Gunakan di FileZilla/SFTP: user=web, pass=Abcd1234!"
