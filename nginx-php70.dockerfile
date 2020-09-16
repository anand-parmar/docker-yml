# Download base image ubuntu 20.04
FROM ubuntu:16.04

# LABEL about the custom image
LABEL maintainer="admin@test.com"
LABEL version="0.1"
LABEL description="PHP7.0,nginx,mysql5.6"

# Disable Prompt During Packages Installation
ARG DEBIAN_FRONTEND=noninteractive

ARG DEV_DOMAIN
ARG NGINX_SSL
ENV DEV_DOMAIN ${DEV_DOMAIN}
ENV NGINX_SSL ${NGINX_SSL}

RUN echo ${DEV_DOMAIN}
RUN echo ${NGINX_SSL}

#install nginx
RUN apt update
RUN apt-get -y install nginx
COPY ./webroot /var/www/html

RUN apt-get install software-properties-common -y
RUN apt-get install -y php7.0 php7.0-fpm php7.0-cli php7.0-common php7.0-mbstring php7.0-gd php7.0-intl php7.0-xml php7.0-mysql php7.0-mcrypt php7.0-zip

#install ssl
RUN apt-get -y install openssl
COPY docker/nginx/generate-ssl.sh /etc/nginx/generate-ssl.sh
RUN chmod +x /etc/nginx/generate-ssl.sh
RUN cd /etc/nginx && ./generate-ssl.sh

COPY docker/nginx/vhost.sh /etc/nginx/vhost.sh
RUN chmod +x /etc/nginx/vhost.sh
RUN cd /etc/nginx && ./vhost.sh

#COPY default /etc/nginx/sites-available/default

RUN apt-get install nano

#RUN apt-get -y install mysql-server
#CMD mysqladmin -u root password root
#CMD service mysql start && mysql -u root -p root -e 'CREATE DATABASE testDB;'
RUN echo "Installing MYSQL..."
RUN { \
echo "mysql-server mysql-server/root_password password root" ; \
echo "mysql-server mysql-server/root_password_again password root" ; \
} | debconf-set-selections \
&& apt-get update && apt-get install -y mysql-server \
&& sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf \
&& chown -R mysql:mysql /var/lib/mysql \
&& usermod -d /var/lib/mysql mysql \
&& /etc/init.d/mysql restart

ARG DB_NAME
ARG DB_USER
ARG DB_PASS
ENV DB_NAME ${DB_NAME}
ENV DB_USER ${DB_USER}
ENV DB_PASS ${DB_PASS}

RUN /etc/init.d/mysql start \
 && mysql --user=root --password=root --execute="CREATE DATABASE ${DB_NAME} CHARACTER SET utf8 COLLATE utf8_bin;" \
 && mysql --user=root --password=root --execute="CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';" \
 && mysql --user=root --password=root --execute="GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX on ${DB_NAME}.* TO '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';"

COPY docker/mysql-entry.sh /etc/mysql-entry.sh
RUN chmod +x /etc/mysql-entry.sh
RUN cd /etc/ && bash ./mysql-entry.sh

# Expose ports
EXPOSE 80

VOLUME /var/lib/mysql


#CMD [/etc/init.d/mysql start && service php7.0-fpm start && nginx -g "daemon off;"]
CMD ["/bin/bash", "-c", "/usr/sbin/service mysql start && /usr/sbin/service php7.0-fpm start && nginx -g 'daemon off;'"]
