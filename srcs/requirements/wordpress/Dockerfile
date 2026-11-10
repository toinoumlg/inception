FROM alpine:3.24

RUN apk update && apk add \
	php85 \
	php85-phar \
	php85-fpm \
	php85-mysqli \
	php85-mbstring \
	wget

RUN mkdir -p /var/www && adduser -D -g www www

RUN wget https://wordpress.org/wordpress-7.0.tar.gz && \
	tar -xzvf wordpress-7.0.tar.gz -C /var/www && \
	rm wordpress-7.0.tar.gz && \
	chown -R www:www /var/www/

RUN wget https://github.com/wp-cli/wp-cli/releases/download/v2.12.0/wp-cli-2.12.0.phar && \
	chmod +x wp-cli-2.12.0.phar && mv wp-cli-2.12.0.phar /usr/bin/wp

COPY conf/www.conf /etc/php85/php-fpm.d/www.conf

ENV CONF=/etc/php85/php-fpm.d/www.conf

COPY --chmod=+x tools/entrypoint.sh /entrypoint.sh

WORKDIR /var/www/wordpress

ENTRYPOINT ["/entrypoint.sh"]