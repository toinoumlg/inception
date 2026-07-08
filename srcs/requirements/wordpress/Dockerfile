FROM alpine:3.24

RUN apk update && apk add \
	php \
	php-phar \
	php-fpm \
	php-mysqli \
	php-mbstring \
	wget

RUN mkdir -p /var/www && adduser -D -g www www

RUN wget https://wordpress.org/wordpress-7.0.tar.gz && \
	tar -xzvf wordpress-7.0.tar.gz -C /var/www && \
	rm wordpress-7.0.tar.gz && \
	chown -R www:www /var/www/

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && mv wp-cli.phar /usr/bin/wp

COPY conf/www.conf /etc/php85/php-fpm.d/www.conf

COPY --chmod=+x tools/entrypoint.sh /entrypoint.sh

WORKDIR /var/www/wordpress

ENTRYPOINT ["/entrypoint.sh"]