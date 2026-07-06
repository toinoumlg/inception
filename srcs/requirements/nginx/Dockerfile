FROM alpine:3.24

RUN apk add nginx

COPY conf/nginx.conf /etc/nginx/nginx.conf

RUN adduser -D -g 'www' www && \
	chown -R www:www /var/lib/nginx && \
	chown -R www:www /www

ENTRYPOINT ["tail", "-f"]