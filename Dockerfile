FROM php:7-fpm

MAINTAINER Mehrdad Dadkhah <mehrdad@dadkhah.me>

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libpq-dev \
        g++ \
        libicu-dev \
        libxml2-dev \
        git \
        vim \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libmagickwand-dev --no-install-recommends \
    && docker-php-ext-configure intl \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install intl \
    && docker-php-ext-install zip \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install pdo_pgsql \
    && docker-php-ext-install soap \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install opcache \
    && docker-php-ext-install mysqli \
    && pecl install imagick  \
    && docker-php-ext-enable imagick \
    && pecl install apcu \
    && docker-php-ext-enable apcu \
    && pecl install xdebug

ENV PHPREDIS_VERSION php7

RUN curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.tar.gz  \
    && mkdir /tmp/redis \
    && tar -xf /tmp/redis.tar.gz -C /tmp/redis \
    && rm /tmp/redis.tar.gz \
    && ( \
    cd /tmp/redis/phpredis-$PHPREDIS_VERSION \
    && phpize \
        && ./configure \
    && make -j$(nproc) \
        && make install \
    ) \
    && rm -r /tmp/redis \
    && docker-php-ext-enable redis

RUN sed -i -e 's/listen.*/listen = 0.0.0.0:9000/' /usr/local/etc/php-fpm.conf

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN usermod -u 1000 www-data

COPY ./opcache.ini /usr/local/etc/php/conf.d/opcache.ini

RUN apt-get update && \
    apt-get -qqy install --no-install-recommends \
        autoconf \
        automake \
        build-essential \
        ca-certificates \
        mercurial \
        cmake \
        libass-dev \
        libgpac-dev \
        libtheora-dev \
        libtool \
        libvdpau-dev \
        libvorbis-dev \
        pkg-config \
        texi2html \
        zlib1g-dev \
        libmp3lame-dev \
        wget \
        yasm


# Run build script

ADD script/buildFFmpeg.sh /build.sh
RUN ["/bin/bash", "/build.sh"]

RUN apt-get purge --auto-remove -y git cmake automake build-essential\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

CMD ["php-fpm"]