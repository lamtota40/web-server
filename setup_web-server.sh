#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Harus dijalankan sebagai root!"
    exit 1
fi

sudo apt update -y

while true; do
clear
echo "======================================"
echo "        Menu Instalasi Server         "
echo "======================================"
echo ""
echo "1. Install Web Server"
echo "2. Certificate Web (HTTPS)"
echo "3. Install FTP/FTPS"
echo "4. Uninstall ALL"
echo "0. Untuk KELUAR"
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

        # Set password MySQL dan phpMyAdmin sebelum install
        MYSQL_PASSWORD="Abcd1234!"
        sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_PASSWORD"
        sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD"
        sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
        sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $MYSQL_PASSWORD"
        sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_PASSWORD"
        sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $MYSQL_PASSWORD"
        sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"

        case $webserver in
            1)
                echo "Anda memilih Apache (LAMP)"
                sudo apt install apache2 php libapache2-mod-php -y
                sudo systemctl enable apache2
                sudo systemctl restart apache2
                # Lanjut install PHP module, MySQL, dan phpMyAdmin
        sudo apt install php-curl php-mysql certbot python python3 -y
        sudo apt install mysql-server phpmyadmin -y
        sudo chown -R www-data:www-data /var/www/html
        sudo chmod -R 755 /var/www/html

        # Setup user MySQL
        sudo mysql <<EOF
CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT
EOF
        sudo systemctl enable mysql
        sudo systemctl restart mysql
                ;;
            2)
                echo "Anda memilih Nginx (LEMP)"
                sudo apt install nginx php-fpm -y
                sudo systemctl enable nginx
                sudo systemctl enable php7.4-fpm || sudo systemctl enable php8.1-fpm
                sudo systemctl restart nginx
                sudo systemctl restart php7.4-fpm || sudo systemctl restart php8.1-fpm
                sudo rm -f /var/www/html/index.nginx-debian.html
                # Lanjut install PHP module, MySQL, dan phpMyAdmin
        sudo apt install php-curl php-mysql certbot python python3 -y
        sudo apt install mysql-server phpmyadmin -y
        sudo chown -R www-data:www-data /var/www/html
        sudo chmod -R 755 /var/www/html

        # Setup user MySQL
        sudo mysql <<EOF
CREATE USER IF NOT EXISTS 'web'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'web'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT
EOF
        sudo systemctl enable mysql
        sudo systemctl restart mysql
                ;;
            *)
                read -p "Tekan [Enter] untuk kembali ke menu utama..."
                ;;
                esac
                read -p "Tekan [Enter] untuk kembali ke menu utama..."
        ;;
    2)
        echo "Pilihan anda: Install SSL Certificate HTTPS"
        echo "jika gagal setting DNS tambahkan CAA : 0 issue "letsencrypt.org""
        read -p "Masukkan domain kamu (contoh: mydomain.com): " domain
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
        read -p "Tekan [Enter] untuk kembali ke menu utama..."
        ;;
            3)
        echo "Pilihan anda: Install FTP/FTPS"
        sudo apt install vsftpd -y
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
sudo sed -i 's/#\s*write_enable=YES/write_enable=YES/' /etc/vsftpd.conf
sudo sed -i 's/#\s*chroot_local_user=YES/chroot_local_user=YES/' /etc/vsftpd.conf
echo "allow_writeable_chroot=YES" | sudo tee -a /etc/vsftpd.conf
sudo systemctl restart vsftpd
sudo systemctl enable vsftpd
read -p "Tekan [Enter] untuk kembali ke menu utama..."
        ;;
4)
    read -p "Apakah kamu yakin akan meng-uninstall semua (y/n): " uninstall
    case $uninstall in
        y|Y)
            echo "Mulai proses uninstall..."

            # Uninstall MySQL dan PHPMyAdmin
            if systemctl list-units --type=service | grep -q mysql; then
                echo "Uninstalling MySQL dan PHPMyAdmin..."
                sudo mysql <<EOF
DROP USER IF EXISTS 'admin'@'LEGES;
EXIT
EOF
                sudo chown -R root:root /var/www/html
                sudo chmod -R 755 /var/www/html
                sudo systemctl disable mysql
                sudo systemctl stop mysql
                sudo DEBIAN_FRONTEND=noninteractive apt remove --purge -y php-curl php-mysql certbot python python3 mysql-server phpmyadmin
            fi

            # Uninstall Apache
            if systemctl list-units --type=service | grep -q apache2; then
                echo "Uninstalling Apache..."
                sudo systemctl stop apache2
                sudo systemctl disable apache2
                sudo apt remove --purge -y python3-certbot-apache
                sudo apt remove --purge -y apache2 php libapache2-mod-php
            fi

            # Uninstall Nginx + PHP-FPM
            if systemctl list-units --type=service | grep -q nginx; then
                echo "Uninstalling Nginx dan PHP-FPM..."
                sudo systemctl stop nginx
                sudo systemctl disable nginx

                if systemctl list-units --type=service | grep -q php7.4-fpm; then
                    sudo systemctl stop php7.4-fpm
                    sudo systemctl disable php7.4-fpm
                fi

                if systemctl list-units --type=service | grep -q php8.1-fpm; then
                    sudo systemctl stop php8.1-fpm
                    sudo systemctl disable php8.1-fpm
                fi

                sudo apt remove --purge -y python3-certbot-nginx
                sudo apt remove --purge -y nginx php-fpm
            fi

            # Uninstall FTP/FTPS (vsftpd)
            if systemctl list-units --type=service | grep -q vsftpd; then
                echo "Uninstalling FTP/FTPS..."
                sudo systemctl stop vsftpd
                sudo systemctl disable vsftpd

                if [ -f /etc/vsftpd.conf.bak ]; then
                    sudo mv /etc/vsftpd.conf.bak /etc/vsftpd.conf
                fi
                sudo apt remove --purge -y vsftpd
            fi

            # Cleanup
            sudo apt autoremove -y
            sudo apt autoclean
            
            #remove user admin
                if id "admin" &>/dev/null; then
                    sudo userdel -r admin
                fi
            echo "Uninstall selesai!..."
            ;;
        n|N)
            echo "Batal uninstall..."
            ;;
        *)
            echo "Pilihan tidak valid!"
            read -p "Tekan [Enter] untuk kembali ke menu utama..."
            ;;
    esac
    ;;
            0)
            echo "Keluar dari program."
            exit 0
            ;;
    *)
        echo "Pilihan tidak tersedia!"
        read -p "Tekan [Enter] untuk kembali ke menu utama..."
        ;;
esac
done


if ! id "web" &>/dev/null; then
        sudo useradd -m -s /bin/false web || true
        echo "web:Abcd1234!" | sudo chpasswd
sudo usermod -aG www-data web
sudo chown -R web:web /var/www/html
sudo usermod -d /var/www/html web
        fi
