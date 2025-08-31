#!/bin/sh

username=$1
version=${2:-'8.3'}
ownership=${3:-'test'}
dir=${4:-'public'}
domain=$username.$ownership

root="/home/$USER/www/$username/$dir"
parent="/home/$USER/www/$username"
block="/etc/nginx/sites-available/$username"

# # Create the Document Root directory
#mkdir -p $root
#sudo chmod -R 755 $parent
# # Assign ownership to your regular user account
#sudo chown -R $USER:$USER $parent

# # Create the Nginx server block file:
sudo tee $block > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain *.$domain;
    listen 443 ssl;
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    root $root;
    index index.html index.htm index.php index.nginx-debian.html;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
        autoindex on;
        #proxy_bind 127.0.0.1;
        #proxy_pass http://127.0.0.1:3000;
        #proxy_set_header    Upgrade \$http_upgrade;
        #proxy_set_header    Connection 'upgrade';
        #proxy_set_header    X-Forwarded-For \$remote_addr;
        #proxy_set_header    Host \$host;
        #proxy_http_version  1.1;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php$version-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root\$fastcgi_script_name;
        include fastcgi_params;
        include snippets/fastcgi-php.conf;
    }

    # A long browser cache lifetime can speed up repeat visits to your page
    location ~* \.(jpg|jpeg|gif|png|webp|svg|woff|woff2|ttf|css|js|ico|xml)$ {
        access_log off;
        log_not_found off;
        expires 360d;
    }

    # disable access to hidden files
    location ~ /\.ht {
        access_log off;
        log_not_found off;
        deny all;
    }
}
EOF

# sudo tee $root'/index.html' > /dev/null <<EOF
# <center><h1>Welcome $username</h1></center> 
# EOF

# # Link to make it available
# # sudo ln -s $block /etc/nginx/sites-enabled/


sudo echo "127.0.0.1 $domain" >> /etc/hosts
# sudo echo "127.0.0.1 *.$domain" >> /etc/hosts

# # Test configuration and reload if successful
sudo nginx -t && sudo service nginx reload

#sudo chmod -R 777 /var/www

printf "\n\n *** Created successfully ***\n\n"

exit
