FROM php:8.2-fpm-alpine

LABEL org.opencontainers.image.title="YOURLS"
LABEL org.opencontainers.image.description="Your Own URL Shortener"
LABEL org.opencontainers.image.url="https://yourls.org/"
LABEL org.opencontainers.image.documentation="https://yourls.org/"
LABEL org.opencontainers.image.vendor="YOURLS Org"
LABEL org.opencontainers.image.authors="YOURLS"
LABEL org.opencontainers.image.licenses="MIT"
LABEL io.artifacthub.package.readme-url="https://raw.githubusercontent.com/YOURLS/YOURLS/master/README.md"

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

RUN apk add --no-cache bash

# renovate: datasource=github-releases depName=YOURLS/YOURLS versioning=composer
ARG YOURLS_VERSION="1.9.2"
ARG YOURLS_SHA256="62a95ba766d62f3305d75944cbfe12d5a90c08c88fbf2f6e67150d36412b916f"

LABEL org.opencontainers.image.version="$YOURLS_VERSION"

ENV YOURLS_VERSION=$YOURLS_VERSION
ENV YOURLS_SHA256=$YOURLS_SHA256

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
COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
