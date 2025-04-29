#!/bin/bash

# Pastikan dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
    echo "Harus dijalankan sebagai root!"
    exit 1
fi

# Update awal
apt update -y

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

            case $webserver in
                1)
                    echo "Anda memilih Apache (LAMP)"
                    apt install -y apache2 php libapache2-mod-php
                    systemctl enable apache2
                    systemctl restart apache2
                    ;;
                2)
                    echo "Anda memilih Nginx (LEMP)"
                    apt install -y nginx php-fpm
                    systemctl enable nginx
                    systemctl enable php7.4-fpm || systemctl enable php8.1-fpm
                    systemctl restart nginx
                    systemctl restart php7.4-fpm || systemctl restart php8.1-fpm
                    rm -f /var/www/html/index.nginx-debian.html
                    ;;
                *)
                    read -p "Tekan [Enter] untuk kembali ke menu utama..."
                    ;;
            esac

            if ! systemctl list-units --type=service | grep -q mysql; then
                MYSQL_PASSWORD="Abcd1234!"
                debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_PASSWORD"
                debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD"
                debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
                debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $MYSQL_PASSWORD"
                debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_PASSWORD"
                debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $MYSQL_PASSWORD"
                debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"

                apt install -y php-curl php-mysql certbot python python3
                apt install -y mysql-server phpmyadmin
                chown -R www-data:www-data /var/www/html
                chmod -R 755 /var/www/html

                mysql <<EOF
CREATE USER IF NOT EXISTS 'web'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'web'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT
EOF
                systemctl enable mysql
                systemctl restart mysql
            fi

            if ! id "web" &>/dev/null; then
                useradd -m -s /bin/bash web
                echo "web:Abcd1234!" | chpasswd
                usermod -aG www-data web
                chown -R web:web /var/www/html
                usermod -d /var/www/html web
            fi

            read -p "Tekan [Enter] untuk kembali ke menu utama..."
            ;;

        2)
            echo "Pilihan anda: Install SSL Certificate HTTPS"
            echo "jika gagal setting DNS tambahkan CAA : 0 issue \"letsencrypt.org\""
            read -p "Masukkan domain kamu (contoh: mydomain.com): " domain
            email="admin@$domain"

            if systemctl list-units --type=service | grep -q apache2; then
                echo "Terdeteksi Apache terinstall."
                apt install -y python3-certbot-apache
                certbot --apache --non-interactive --agree-tos --redirect -m "$email" -d "$domain"
                systemctl restart apache2
            elif systemctl list-units --type=service | grep -q nginx; then
                echo "Terdeteksi Nginx terinstall."
                apt install -y python3-certbot-nginx
                certbot --nginx --non-interactive --agree-tos --redirect -m "$email" -d "$domain"
                systemctl restart nginx
            else
                echo "Anda belum menginstal Web Server (Apache atau Nginx)."
            fi
            read -p "Tekan [Enter] untuk kembali ke menu utama..."
            ;;

        3)
            echo "Pilihan anda: Install FTP/FTPS"
            apt install -y vsftpd
            cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
            sed -i 's/#\s*write_enable=YES/write_enable=YES/' /etc/vsftpd.conf
            sed -i 's/#\s*chroot_local_user=YES/chroot_local_user=YES/' /etc/vsftpd.conf
            echo "allow_writeable_chroot=YES" | tee -a /etc/vsftpd.conf
            systemctl restart vsftpd
            systemctl enable vsftpd
            read -p "Tekan [Enter] untuk kembali ke menu utama..."
            ;;

        4)
            read -p "Apakah kamu yakin akan meng-uninstall semua (y/n): " uninstall
            case $uninstall in
                y|Y)
                    echo "Mulai proses uninstall..."

                    if systemctl list-units --type=service | grep -q mysql; then
                        mysql <<EOF
DROP USER IF EXISTS 'web'@'localhost';
EOF
                        chown -R root:root /var/www/html
                        chmod -R 755 /var/www/html
                        systemctl disable mysql
                        systemctl stop mysql
                        DEBIAN_FRONTEND=noninteractive apt remove --purge -y php-curl php-mysql certbot python python3 mysql-server phpmyadmin
                    fi

                    if systemctl list-units --type=service | grep -q apache2; then
                        systemctl stop apache2
                        systemctl disable apache2
                        apt remove --purge -y python3-certbot-apache apache2 php libapache2-mod-php
                    fi

                    if systemctl list-units --type=service | grep -q nginx; then
                        systemctl stop nginx
                        systemctl disable nginx
                        systemctl stop php7.4-fpm || true
                        systemctl disable php7.4-fpm || true
                        systemctl stop php8.1-fpm || true
                        systemctl disable php8.1-fpm || true
                        apt remove --purge -y python3-certbot-nginx nginx php-fpm
                    fi

                    if systemctl list-units --type=service | grep -q vsftpd; then
                        systemctl stop vsftpd
                        systemctl disable vsftpd
                        [ -f /etc/vsftpd.conf.bak ] && mv /etc/vsftpd.conf.bak /etc/vsftpd.conf
                        apt remove --purge -y vsftpd
                    fi

                    apt autoremove -y
                    apt autoclean

                    if id "web" &>/dev/null; then
                        userdel -r web
                    fi

                    echo "Uninstall selesai!"
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
