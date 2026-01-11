FROM php:8.5-apache

# install the PHP extensions we need
RUN set -eux; \
    docker-php-ext-install -j "$(nproc)" \
    bcmath \
    pdo_mysql \
    mysqli

# set recommended PHP.ini settings
# see https://www.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
    } > "$PHP_INI_DIR/conf.d/opcache-recommended.ini"

RUN a2enmod rewrite expires

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
COPY files/vhost.conf $APACHE_CONFDIR/sites-available/000-default.conf
COPY files/vhost-https.conf $APACHE_CONFDIR/sites-available/default-ssl.conf
COPY files/ports.conf $APACHE_CONFDIR/ports.conf

EXPOSE 8080/tcp
EXPOSE 8443/tcp

ENTRYPOINT ["container-entrypoint.sh"]
CMD ["apache2-foreground"]

#checkov:skip=CKV_DOCKER_2:Not implemented
#checkov:skip=CKV_DOCKER_3:Defined upstream
