FROM php:7.2-%%VARIANT%%

# install the PHP extensions we need
RUN set -eux; \
    docker-php-ext-install -j "$(nproc)" opcache pdo_mysql mysqli

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini
%%VARIANT_EXTRAS%%

ENV YOURLS_VERSION %%VERSION%%
ENV YOURLS_SHA256 %%SHA256%%

RUN set -eux; \
    curl -o yourls.tar.gz -fsSL "https://github.com/YOURLS/YOURLS/archive/${YOURLS_VERSION}.tar.gz"; \
    echo "$YOURLS_SHA256 *yourls.tar.gz" | sha256sum -c -; \
# upstream tarballs include ./YOURLS-${YOURLS_VERSION}/ so this gives us /usr/src/YOURLS-${YOURLS_VERSION}
    tar -xf yourls.tar.gz -C /usr/src/; \
# move back to a common /usr/src/yourls
    mv "/usr/src/YOURLS-${YOURLS_VERSION}" /usr/src/yourls; \
    rm yourls.tar.gz; \
    chown -R www-data:www-data /usr/src/yourls

COPY docker-entrypoint.sh /usr/local/bin/
COPY config-docker.php /usr/src/yourls/user/
%%VARIANT_FILES%%
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["%%CMD%%"]
