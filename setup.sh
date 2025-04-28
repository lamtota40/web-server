#!/bin/bash

clear
echo "======================================"
echo "        Menu Instalasi Server         "
echo "======================================"
echo ""
echo "1. Install Web Server"
echo "   1.1 APACHE (LAMP: Linux + Apache + MySQL + PHP)"
echo "   1.2 NGINX (LEMP: Linux + Nginx + MySQL + PHP)"
echo ""
echo "2. Install FTP/FTPS"
echo ""
echo "3. Certificate Web (HTTPS)"
echo ""
echo "4. Uninstall"
echo ""
echo "======================================"
read -p "Masukan input anda: " pilihan

case $pilihan in
    1.1)
        echo "Pilihan anda: Install LAMP (Apache)"
        # Nanti di sini kamu isi script instalasi LAMP
        ;;
    1.2)
        echo "Pilihan anda: Install LEMP (Nginx)"
        # Nanti di sini kamu isi script instalasi LEMP
        ;;
    2)
        echo "Pilihan anda: Install FTP/FTPS"
        # Nanti di sini kamu isi script instalasi FTP
        ;;
    3)
        echo "Pilihan anda: Install SSL Certificate HTTPS"
        # Nanti di sini kamu isi script SSL Let's Encrypt
        ;;
    4)
        echo "Pilihan anda: Uninstall semua"
        # Nanti di sini kamu isi script uninstall
        ;;
    *)
        echo "Pilihan tidak tersedia!"
        ;;
esac


sudo apt update -y
sudo apt install apache2 php php-curl libapache2-mod-php php-mysql -y
sudo apt install mysql-server phpmyadmin -y

sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

sudo mysql <<EOF
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'Abcd1234!';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT
EOF

sudo systemctl enable mysql
sudo systemctl restart mysql

sudo apt install vsftpd openssl -y
# Buat SSL sertifikat sendiri
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/vsftpd-selfsigned.key \
    -out /etc/ssl/certs/vsftpd-selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=IT Department/CN=localhost"
# Buat user admin dengan home di /var/www/html
sudo useradd -m -d /var/www/html -s /bin/bash admin
echo "admin:Abcd123!" | sudo chpasswd
# Pastikan ownership folder /var/www/html ke user admin
sudo chown -R admin:admin /var/www/html
# Backup konfigurasi vsftpd
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
# Setting konfigurasi baru vsftpd
sudo bash -c 'cat > /etc/vsftpd.conf' <<EOF
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES

# SSL Settings
ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
rsa_cert_file=/etc/ssl/certs/vsftpd-selfsigned.crt
rsa_private_key_file=/etc/ssl/private/vsftpd-selfsigned.key

# Pasang userlist
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO

# Port 21
listen_port=21
EOF
# Tambahkan admin ke userlist
echo "admin" | sudo tee /etc/vsftpd.userlist

# Restart vsftpd
sudo systemctl restart vsftpd
sudo systemctl enable vsftpd

read -p "Masukkan domain kamu (contoh: example.com): " domain
email="admin@$domain"

sudo apt install -y certbot python3-certbot-apache
sudo certbot --apache --non-interactive --agree-tos --redirect -m "$email" -d "$domain"
sudo systemctl restart apache2

echo "Web server already instal"


sudo apt install nginx php-fpm -y

# Aktifkan Nginx dan MySQL saat boot
sudo systemctl enable nginx
sudo systemctl enable php7.4-fpm || sudo systemctl enable php8.1-fpm

# Restart semua service
sudo systemctl restart nginx
sudo systemctl restart php7.4-fpm || sudo systemctl restart php8.1-fpm

# Hapus file index.html bawaan
sudo rm -f /var/www/html/index.nginx-debian.html


