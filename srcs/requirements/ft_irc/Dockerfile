FROM alpine:3.24

RUN apk update && apk add \
	git \
	make \
	g++

RUN git clone https://github.com/toinoumlg/ft_irc.git

WORKDIR /ft_irc

RUN make

ENTRYPOINT ["./ircserv", "4432", "123456"]