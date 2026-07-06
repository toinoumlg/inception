FROM alpine:3.24

RUN apk add \
	php \
	php-fpm \
	php-mysqli \
    php-json \
    php-mbstring \
    php-zip \
    php-gd \
    php-curl 

RUN mkdir -p /var/www/html && \
    mkdir -p /var/run/php

RUN wget https://wordpress.org/latest.tar.gz && \
	tar -xzvf latest.tar.gz -C /var/www/html && \
	rm latest.tar.gz && 
	chown -R www:www /var/www/html

COPY conf/www.conf /etc/php83/php-fpm.d/www.conf

COPY conf/wp-config.php /var/www/html

EXPOSE 9000

VOLUME ["/var/www/html"]

ENTRYPOINT ["sh", "-c", "php-fpm83 -F"]