#!/usr/bin/env bash

if [ "$NGINX_SSL" = true ]; then
cat > /etc/nginx/sites-available/default <<- EOF
server {
    listen 80;
    server_name $DEV_DOMAIN;
    return 301 https://$DEV_DOMAIN\$request_uri;
}
server {
    listen 443 ssl;
    index index.php index.html;
    server_name $DEV_DOMAIN;
    error_log  /var/log/nginx/error_manual.log;
    access_log /var/log/nginx/access_manual.log;
    root /var/www/html;

    ssl_certificate /etc/nginx/ssl-cert.crt;
    ssl_certificate_key /etc/nginx/ssl-cert.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
      #try_files $uri $uri/ =404;
      try_files $uri $uri/ /index.php?$args;
    }


    location ~ \.php$ {
      include snippets/fastcgi-php.conf;
      fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    }

}
EOF
else
cat > /etc/nginx/sites-available/default <<- EOF
server {
    index index.php index.html;
    server_name $DEV_DOMAIN;
    error_log  /var/log/nginx/error_manual.log;
    access_log /var/log/nginx/access_manual.log;
    root /var/www/html;

    location / {
      #try_files $uri $uri/ =404;
      try_files $uri $uri/ /index.php?$args;
    }


    location ~ \.php$ {
      include snippets/fastcgi-php.conf;
      fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    }

}
EOF
fi