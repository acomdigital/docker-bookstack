# Adapted from https://github.com/solidnerd/docker-bookstack
FROM php:7.4-apache-buster

ENV BOOKSTACK_VERSION=21.10.3 \
    COMPOSER_VERSION=1.10.16

COPY current-theme.patch /

RUN apt-get update && apt-get install -y --no-install-recommends git zlib1g-dev libfreetype6-dev libjpeg62-turbo-dev libmcrypt-dev libpng-dev wget libldap2-dev libtidy-dev libxml2-dev fontconfig fonts-freefont-ttf wkhtmltopdf tar curl libzip-dev unzip \
    && docker-php-ext-install -j$(nproc) dom pdo pdo_mysql zip \
    && docker-php-ext-configure ldap \
    && docker-php-ext-install -j$(nproc) ldap \
    && docker-php-ext-configure gd --with-freetype=usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-source delete \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/cache/* /var/tmp/* /etc/apache2/sites-enabled/000-*.conf \
    && wget https://github.com/BookStackApp/BookStack/archive/v${BOOKSTACK_VERSION}.tar.gz -O bookstack.tar.gz \
    && tar -xf bookstack.tar.gz && mv BookStack-${BOOKSTACK_VERSION} /var/www/bookstack && rm bookstack.tar.gz  \
    && cd /tmp && curl -sS https://getcomposer.org/installer | php -- --version=${COMPOSER_VERSION} \
    && cd /var/www/bookstack && /tmp/composer.phar install \
    && rm -rf /tmp/composer.phar /root/.composer \
    && git apply --whitespace=fix -p2 < /current-theme.patch \
    && chown -R www-data:www-data /var/www/bookstack \
    && a2enmod rewrite \
    && sed -i "s/Listen 80/Listen 8080/" /etc/apache2/ports.conf \
    && rm -f /etc/apache2/sites-available/*.conf \
    && rm -f /current-theme.patch

COPY bookstack.conf /etc/apache2/sites-enabled/000-default.conf

COPY php.ini /usr/local/etc/php/php.ini
COPY docker-entrypoint.sh /bin/docker-entrypoint.sh

WORKDIR /var/www/bookstack 

# www-data
USER 33

VOLUME ["/var/www/bookstack/public/uploads","/var/www/bookstack/storage/uploads"]

ENV RUN_APACHE_USER=www-data \
    RUN_APACHE_GROUP=www-data

EXPOSE 8080

ENTRYPOINT ["/bin/docker-entrypoint.sh"]

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="MIT" \
    org.label-schema.name="bookstack" \
    org.label-schema.vendor="col-panic" \
    org.label-schema.url="https://github.com/col-panic/docker-bookstack/" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/col-panic/docker-bookstack.git" \
    org.label-schema.vcs-type="Git"
