#!/bin/bash

sudo apt update -y
sudo apt install php-curl php-mysql certbot python python3 -y
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

clear
echo "======================================"
echo "        Menu Instalasi Server         "
echo "======================================"
echo ""
echo "1. Install Web Server"
echo "2. Install FTP/FTPS"
echo "3. Certificate Web (HTTPS)"
echo "4. Uninstall"
echo ""
echo "======================================"
read -p "Masukan input anda: " pilihan

case $pilihan in
    1)
        clear
        echo "======================================"
        echo "        Pilih Web Server             "
        echo "======================================"
        echo "1. Apache (LAMP: Linux + Apache + MySQL + PHP)"
        echo "2. Nginx (LEMP: Linux + Nginx + MySQL + PHP)"
        echo "======================================"
        read -p "Masukan input anda untuk memilih web server: " webserver
        case $webserver in
            1)
                echo "Anda memilih Apache (LAMP)"
                sudo apt install apache2 php libapache2-mod-php -y
                ;;
            2)
                echo "Anda memilih Nginx (LEMP)"
                sudo apt install nginx php-fpm -y
                sudo systemctl enable nginx
                sudo systemctl enable php7.4-fpm || sudo systemctl enable php8.1-fpm
                sudo systemctl restart nginx
                sudo systemctl restart php7.4-fpm || sudo systemctl restart php8.1-fpm
                sudo rm -f /var/www/html/index.nginx-debian.html
                ;;
            *)
                echo "Pilihan tidak tersedia!"
                ;;
        esac
        ;;
    2)
        echo "Pilihan anda: Install FTP/FTPS"
        sudo apt install vsftpd openssl -y
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/vsftpd-selfsigned.key \
    -out /etc/ssl/certs/vsftpd-selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=IT Department/CN=localhost"
sudo useradd -m -d /var/www/html -s /bin/bash admin
echo "admin:Abcd1234!" | sudo chpasswd
sudo chown -R admin:admin /var/www/html
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak

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
echo "admin" | sudo tee /etc/vsftpd.userlist
sudo systemctl restart vsftpd
sudo systemctl enable vsftpd
        ;;
    3)
        echo "Pilihan anda: Install SSL Certificate HTTPS"
read -p "Masukkan domain kamu (contoh: example.com): " domain
email="admin@$domain"

# Cek apakah apache2 atau nginx terinstall
if systemctl list-units --type=service | grep -q apache2; then
    echo "Terdeteksi Apache terinstall."
    sudo apt install -y python3-certbot-apache
    sudo certbot --apache --non-interactive --agree-tos --redirect -m "$email" -d "$domain"
    sudo systemctl restart apache2
elif systemctl list-units --type=service | grep -q nginx; then
    echo "Terdeteksi Nginx terinstall."
    sudo apt install -y python3-certbot-nginx
    sudo certbot --nginx --non-interactive --agree-tos --redirect -m "$email" -d "$domain"
    sudo systemctl restart nginx
else
    echo "Anda belum menginstal Web Server (Apache atau Nginx)."
fi

        ;;
    4)
        echo "Pilihan anda: Uninstall semua"
        # Nanti di sini kamu isi script uninstall
        ;;
    *)
        echo "Pilihan tidak tersedia!"
        ;;
esac
