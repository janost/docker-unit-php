FROM alpine:3.15 as builder
ARG PHP_VERSION
ARG UNIT_VERSION
RUN apk add --no-cache curl alpine-sdk openssl-dev pcre2-dev php${PHP_VERSION}-embed php${PHP_VERSION}-dev
RUN mkdir /tmp/unitbuild && curl https://unit.nginx.org/download/unit-${UNIT_VERSION}.tar.gz | tar -xz --strip 1 -C /tmp/unitbuild
WORKDIR /tmp/unitbuild
RUN ./configure --prefix="/usr" --state="/var/lib/unit" --control="unix:/run/control.unit.sock" --pid="/run/unit.pid" --log="/var/log/unit.log" --modules="/usr/lib/unit/modules" --openssl
RUN ./configure php --module=php${PHP_VERSION} --config=php-config${PHP_VERSION}
RUN make -j $(nproc)
RUN make install

FROM alpine:3.15 as app
ARG PHP_VERSION
RUN apk add --no-cache \
    php${PHP_VERSION}-embed php${PHP_VERSION}-curl php${PHP_VERSION}-gd php${PHP_VERSION}-mbstring php${PHP_VERSION}-pecl-imagick \
    php${PHP_VERSION}-mysqli php${PHP_VERSION}-opcache php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-pecl-apcu \
    php${PHP_VERSION}-dom php${PHP_VERSION}-exif php${PHP_VERSION}-fileinfo php${PHP_VERSION}-iconv
RUN mkdir -p /var/lib/unit /usr/lib/unit/modules /app
COPY --from=builder /usr/sbin/unitd /usr/sbin
COPY --from=builder /usr/lib/unit/modules/* /usr/lib/unit/modules
COPY conf.json /var/lib/unit/
CMD ["/usr/sbin/unitd", "--no-daemon"]
