FROM php:8.4-fpm-alpine

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
ARG YOURLS_VERSION="1.10.3"
ARG YOURLS_SHA256="71749ae9b3950d6a7c043b1240aba8645e912c3c22eac5abfb6ae3cc576ff740"

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

COPY --chown=www-data:www-data config-container.php /usr/src/yourls/user/
COPY container-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["container-entrypoint.sh"]
CMD ["php-fpm"]

#checkov:skip=CKV_DOCKER_2:Not implemented
#checkov:skip=CKV_DOCKER_3:Defined upstream
