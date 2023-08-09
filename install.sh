#!/bin/sh

script_log_file="script_log.log"
green_color="\033[1;32m"
no_color="\033[0m"
current_user=$(logname)

printf "# "$no_color"PREPAIRE INSTALLING";
rm -rf /var/lib/dpkg/lock >> $script_log_file 2>/dev/null
rm -rf /var/lib/dpkg/lock-frontend >> $script_log_file 2>/dev/null
rm -rf /var/cache/apt/archives/lock >> $script_log_file 2>/dev/null
sudo apt-get update  >> $script_log_file 2>/dev/null
printf $green_color" [SUCCESS]\n";


printf "# "$no_color"REMOVING APACHE";
sudo apt-get purge apache -y >> $script_log_file 2>/dev/null
sudo apt-get purge apache* -y >> $script_log_file 2>/dev/null
sudo kill -9 $(sudo lsof -t -i:80) >> $script_log_file 2>/dev/null
sudo kill -9 $(sudo lsof -t -i:443) >> $script_log_file 2>/dev/null
printf $green_color" [SUCCESS]\n";


printf "# "$no_color"INSTALLING NGINX";
sudo apt-get update   >> $script_log_file 2>/dev/null
sudo apt install nginx -y >> $script_log_file 2>/dev/null
sudo sed -i "/sites-enabled/a server_names_hash_bucket_size 64;\nclient_max_body_size 1000M;\nproxy_connect_timeout   3600;\nproxy_send_timeout      3600;\nproxy_read_timeout      3600;\nsend_timeout            3600;\nclient_body_timeout     3600;\nfastcgi_read_timeout 3600s;" /etc/nginx/nginx.conf >> $script_log_file 2>/dev/null
printf $green_color" [SUCCESS]\n";


for version in 8.2 8.1 8.0 7.4;
do
    printf "# "$no_color"INSTALLING PHP "$version;
    sudo apt-get update  >> $script_log_file 2>/dev/null
    sudo apt install lsb-release ca-certificates apt-transport-https software-properties-common -y >> $script_log_file 2>/dev/null
    sudo add-apt-repository ppa:ondrej/php -y >> $script_log_file 2>/dev/null
    sudo apt-get update  >> $script_log_file 2>/dev/null
    sudo apt install php$version -y >> $script_log_file 2>/dev/null
    printf $green_color" [SUCCESS]\n";

    printf "# "$no_color"INSTALLING PHP EXTENSIONS";
    sudo apt install php$version openssl php$version-fpm php$version-common php$version-curl php$version-mbstring php$version-mysql php$version-xml php$version-zip php$version-gd php$version-cli php$version-xml php$version-imagick php$version-xml php$version-intl php-mysql -y >> $script_log_file 2>/dev/null
    printf $green_color" [SUCCESS]\n";

    printf "# "$green_color"CHANGING PHP FPM UPLOAD VALUES";
    sudo sed -i 's/post_max_size = 8M/post_max_size = 1000M/g' /etc/php/$version/fpm/php.ini >> $script_log_file 2>/dev/null
    sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 1000M/g' /etc/php/$version/fpm/php.ini >> $script_log_file 2>/dev/null
    sudo sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php/$version/fpm/php.ini >> $script_log_file 2>/dev/null
    sudo sed -i 's/memory_limit = 128/memory_limit = 12800/g' /etc/php/$version/fpm/php.ini >> $script_log_file 2>/dev/null
    sudo sed -i 's/user = www-data/user = '$current_user'/g' /etc/php/$version/fpm/pool.d/www.conf >> $script_log_file 2>/dev/null
    sudo service php$version-fpm restart >> $script_log_file 2>/dev/null
    printf $green_color" [SUCCESS]\n";
done


printf "# "$no_color"INSTALLING COMPOSER";
sudo apt-get update  >> $script_log_file 2>/dev/null
sudo apt-get purge composer -y >> $script_log_file 2>/dev/null
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" >> $script_log_file 2>/dev/null
php composer-setup.php >> $script_log_file  2>/dev/null
sudo mv composer.phar /usr/local/bin/composer >> $script_log_file 2>/dev/null
printf $green_color" [SUCCESS]\n";


printf "# "$no_color"RESTARTING NGINX";
sudo pkill -f nginx & wait $! >> $script_log_file 2>/dev/null
sudo systemctl start nginx >> $script_log_file 2>/dev/null
sudo service nginx restart >> $script_log_file 2>/dev/null
printf $green_color" [SUCCESS]\n";


printf "# "$no_color"PREPAIRE SSL CERTIFICATE";
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/C=EG/ST=London/L=London/O=Global Security/OU=IT Department/CN=example.com"
printf $green_color" [SUCCESS]\n";


printf "# "$no_color"Instaling phpmyadmin";
sudo apt install unzip -y >> $script_log_file 2>/dev/null
sudo wget -O /usr/share/phpmyadmin.zip https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip >> $script_log_file 2>/dev/null
sudo unzip /usr/share/phpmyadmin.zip -d /usr/share/ >> $script_log_file 2>/dev/null
sudo mv /usr/share/phpMyAdmin-5.2.1-all-languages /usr/share/phpmyadmin >> $script_log_file 2>/dev/null
sudo rm /usr/share/phpmyadmin.zip >> $script_log_file 2>/dev/null
sudo cat << EOT >> /usr/share/phpmyadmin/config.inc.php 
<?php
declare(strict_types=1);
\$cfg['blowfish_secret'] = '';
\$cfg['ExecTimeLimit'] = 0;
\$i = 0;
\$i++;
\$cfg['Servers'][\$i]['auth_type'] = 'config';
\$cfg['Servers'][\$i]['host'] = 'localhost';
\$cfg['Servers'][\$i]['user'] = 'root';
\$cfg['Servers'][\$i]['password'] = '';
\$cfg['Servers'][\$i]['compress'] = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = true;

\$cfg['UploadDir'] = '';
\$cfg['SaveDir'] = '';
\$cfg['TempDir'] = '/tmp';
EOT
printf $green_color" [SUCCESS]\n";
exit


printf "# "$no_color"CREATING NGINX CONFIGURATION";
sudo rm -rf /etc/nginx/sites-available/default /etc/nginx/sites-enabled >> $script_log_file 2>/dev/null
sudo ln -s /etc/nginx/sites-available /etc/nginx/sites-enabled >> $script_log_file 2>/dev/null
sudo touch /etc/nginx/conf.d/default.conf >> $script_log_file 2>/dev/null
sudo bash -c "echo 'server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl;
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html index.php;
    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
        include fastcgi_params;
        include snippets/fastcgi-php.conf;
    }

    location /phpmyadmin {
        root /usr/share/;
        index index.php index.html index.htm;
        location ~ ^/phpmyadmin/(.+\.php)$ {
            try_files \$uri =404;
            root /usr/share/;
            fastcgi_pass unix:/run/php/php8.1-fpm.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            include /etc/nginx/fastcgi_params;
        }
        location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
            root /usr/share/;
        }
    }
}' > /etc/nginx/conf.d/default.conf" >> $script_log_file 2>/dev/null

sudo chown -R ${USER}:${USER} /var/www >> $script_log_file 2>/dev/null
sudo chmod -R 755 /var/www >> $script_log_file 2>/dev/null
printf $green_color" [SUCCESS]\n";


printf "# "$no_color"RESTARTING NGINX";
sudo pkill -f nginx & wait $! >> $script_log_file 2>/dev/null
sudo systemctl start nginx >> $script_log_file 2>/dev/null
sudo service nginx restart >> $script_log_file 2>/dev/null
printf $green_color" [SUCCESS]\n";

if ! [ -x "$(command -v mysql)"  >> $script_log_file 2>/dev/null ]; then
printf "# "$no_color"INSTALLING MYSQL";
sudo apt-get -qq install mysql-server  >> $script_log_file 2>/dev/null
printf $green_color" [SUCCESS]\n";
fi

printf "# "$no_color"Configure MYSQL";
sudo mysql > /dev/null << EOF 
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';
FLUSH PRIVILEGES;
EOF
printf $green_color" [SUCCESS]\n";


printf "# "$no_color"INSTALLING git";
sudo apt-get update   >> $script_log_file 2>/dev/null
sudo apt install git -y >> $script_log_file 2>/dev/null
printf $green_color" [SUCCESS]\n";

printf "# "$no_color"INSTALLING NPM";
sudo apt install npm -y >> $script_log_file 2>/dev/null
printf $green_color" [SUCCESS]\n";

printf "# "$no_color"INSTALLING nodejs";
sudo curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash - >> $script_log_file 2>/dev/null
sudo apt install nodejs -y >> $script_log_file 2>/dev/null
printf $green_color" [SUCCESS]\n";


printf "# "$no_color"PREPAIRE bashrc";
cat << EOT >> /home/$current_user/.bashrc 
alias composer7.4='/usr/bin/php7.4 /usr/local/bin/composer'
alias composer8.0='/usr/bin/php8.0 /usr/local/bin/composer'
alias composer8.1='/usr/bin/php8.1 /usr/local/bin/composer'
alias composer8.2='/usr/bin/php8.2 /usr/local/bin/composer'
alias commit='git add . && git commit '
alias push='git push origin'
alias pull='git pull origin'
alias checkout='git checkout'
alias merge='git merge'
EOT

printf "# "$no_color"FINALIZE INSTALLING";
sudo apt-get autoremove -y >> $script_log_file 2>/dev/null
sudo apt-get autoclean -y >> $script_log_file 2>/dev/null
sudo apt-get update  >> $script_log_file 2>/dev/null
printf $green_color" [SUCCESS]\n";

echo $green_color"[End]";