FROM alpine:3.20 as builder
ARG PHP_VERSION
ARG UNIT_VERSION
RUN apk add --no-cache curl alpine-sdk openssl-dev pcre2-dev php${PHP_VERSION}-embed php${PHP_VERSION}-dev && \
    mkdir /tmp/unitbuild && curl https://unit.nginx.org/download/unit-${UNIT_VERSION}.tar.gz | tar -xz --strip 1 -C /tmp/unitbuild && \
    ln -fs /usr/bin/php-config${PHP_VERSION} /usr/bin/php-config && \
    ln -fs /usr/bin/php${PHP_VERSION} /usr/bin/php && \
    ln -fs /usr/lib/libphp${PHP_VERSION}.so /usr/lib/libphp.so
WORKDIR /tmp/unitbuild
RUN ./configure --prefix="/usr" --state="/var/lib/unit" --control="unix:/run/control.unit.sock" --pid="/run/unit.pid" --log="/var/log/unit.log" --modules="/usr/lib/unit/modules" --openssl && \
    ./configure php --module=php${PHP_VERSION} --config=php-config${PHP_VERSION} && \
    make -j $(nproc) && \
    make install

FROM alpine:3.20 as app
ARG PHP_VERSION
RUN apk add --no-cache \
    php${PHP_VERSION}-embed php${PHP_VERSION}-curl php${PHP_VERSION}-gd php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-mysqli php${PHP_VERSION}-opcache php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-pecl-apcu \
    php${PHP_VERSION}-pecl-redis php${PHP_VERSION}-dom php${PHP_VERSION}-exif php${PHP_VERSION}-fileinfo php${PHP_VERSION}-iconv php${PHP_VERSION}-intl && \
    apk add --no-cache php${PHP_VERSION}-pecl-imagick --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ && \
    mkdir -p /var/lib/unit /usr/lib/unit/modules /app && \
    ln -fs /usr/bin/php-config${PHP_VERSION} /usr/bin/php-config && \
    ln -fs /usr/bin/php${PHP_VERSION} /usr/bin/php && \
    ln -fs /usr/lib/libphp${PHP_VERSION}.so /usr/lib/libphp.so
COPY --from=builder /usr/sbin/unitd /usr/sbin
COPY --from=builder /usr/lib/unit/modules/* /usr/lib/unit/modules
COPY conf.json /var/lib/unit/
CMD ["/usr/sbin/unitd", "--no-daemon"]
