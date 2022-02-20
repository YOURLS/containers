ARG PHP_VERSION="8.0"
ARG PHP_VARIANT="fpm"

FROM php:${PHP_VERSION}-${PHP_VARIANT}

ARG YOURLS_VERSION="1.8.2"
ARG YOURLS_SHA256="6d818622e3ba1d5785c2dbcc088be6890f5675fd4f24a2e3111eda4523bbd7ae"

LABEL org.opencontainers.image.title="YOURLS"
LABEL org.opencontainers.image.description="Your Own URL Shortener"
LABEL org.opencontainers.image.url="https://yourls.org/"
LABEL org.opencontainers.image.documentation="https://yourls.org/"
LABEL org.opencontainers.image.vendor="YOURLS Org"
LABEL org.opencontainers.image.authors="YOURLS"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.version="$YOURLS_VERSION"
LABEL org.opencontainers.image.base.name="docker.io/library/php:${PHP_VERSION}-${PHP_VARIANT}"

# install the PHP extensions we need
RUN set -eux; \
    docker-php-ext-install -j "$(nproc)" bcmath opcache pdo_mysql mysqli

# set recommended PHP.ini settings
# see https://www.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini



RUN set -eux; \
    curl -o yourls.tar.gz -fsSL "https://github.com/YOURLS/YOURLS/archive/${YOURLS_VERSION}.tar.gz"; \
    echo "$YOURLS_SHA256 *yourls.tar.gz" | sha256sum -c -; \
# upstream tarballs include ./YOURLS-${YOURLS_VERSION}/ so this gives us /usr/src/YOURLS-${YOURLS_VERSION}
    tar -xf yourls.tar.gz -C /usr/src/; \
# move back to a common /usr/src/yourls
    mv "/usr/src/YOURLS-${YOURLS_VERSION}" /usr/src/yourls; \
    rm yourls.tar.gz; \
    chown -R www-data:www-data /usr/src/yourls

COPY --chown=www-data:www-data config-docker.php /usr/src/yourls/user/
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
