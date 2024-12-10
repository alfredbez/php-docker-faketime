FROM php:8.3-cli

RUN apt-get update && apt-get install -y \
    libfaketime \
    git \
    zip \
    unzip \
    libzip-dev \
    libpq-dev \
    libicu-dev \
    libxml2-dev \
    librabbitmq-dev \
    libgmp-dev \
    libpng-dev \
    libbz2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/faketime && \
    find / -name "libfaketime.so*" 2>/dev/null | xargs -I {} cp {} /opt/faketime/ && \
    ls -la /opt/faketime/

RUN docker-php-ext-install \
    bcmath \
    bz2 \
    gd \
    gmp \
    intl \
    mysqli \
    opcache \
    pcntl \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    soap \
    sockets \
    zip

RUN pecl install \
    amqp \
    apcu \
    redis \
    && docker-php-ext-enable \
    amqp \
    apcu \
    redis

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN echo '#!/bin/bash\n\
    export LD_PRELOAD=$(find /opt/faketime -name "libfaketime.so*" | head -n 1)\n\
    export DONT_FAKE_MONOTONIC=1\n\
    export FAKETIME_NO_CACHE=1\n\
    if [ -n "$FAKETIME" ]; then\n\
    export FAKETIME="$FAKETIME"\n\
    fi\n\
    exec "$@"' > /usr/local/bin/with-faketime && \
    chmod +x /usr/local/bin/with-faketime

WORKDIR /app

ENTRYPOINT ["/usr/local/bin/with-faketime"]

