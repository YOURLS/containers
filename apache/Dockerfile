FROM php:8.0-apache

LABEL org.opencontainers.image.title="YOURLS"
LABEL org.opencontainers.image.description="Your Own URL Shortener"
LABEL org.opencontainers.image.url="https://yourls.org/"
LABEL org.opencontainers.image.documentation="https://yourls.org/"
LABEL org.opencontainers.image.vendor="YOURLS Org"
LABEL org.opencontainers.image.authors="YOURLS"
LABEL org.opencontainers.image.version="1.8.2"

# install the PHP extensions we need
RUN set -eux; \
    docker-php-ext-install -j "$(nproc)" bcmath opcache pdo_mysql mysqli

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN a2enmod rewrite expires

RUN set -eux; \
    version="1.8.2"; \
    sha256="6d818622e3ba1d5785c2dbcc088be6890f5675fd4f24a2e3111eda4523bbd7ae"; \
    curl -o yourls.tar.gz -fsSL "https://github.com/YOURLS/YOURLS/archive/${version}.tar.gz"; \
    echo "$sha256 *yourls.tar.gz" | sha256sum -c -; \
# upstream tarballs include ./YOURLS-${version}/ so this gives us /usr/src/YOURLS-${version}
    tar -xf yourls.tar.gz -C /usr/src/; \
# move back to a common /usr/src/yourls
    mv "/usr/src/YOURLS-${version}" /usr/src/yourls; \
    rm yourls.tar.gz; \
    chown -R www-data:www-data /usr/src/yourls

COPY --chown=www-data:www-data config-docker.php /usr/src/yourls/user/
COPY docker-entrypoint.sh /usr/local/bin/
COPY .htaccess /usr/src/yourls/
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
