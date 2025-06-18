sudo apt update
sudo apt install -y apache2 php php-curl libapache2-mod-php php-mysql mysql-server

pass=Abcd1234!
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $pass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $pass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $pass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin
