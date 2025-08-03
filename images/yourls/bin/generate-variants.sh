#!/bin/bash
set -e

declare -rA cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
	[fpm-alpine]='php-fpm'
)

declare -rA extras=(
	[apache]='RUN a2enmod rewrite expires'
	[fpm]=''
	[fpm-alpine]='RUN apk add --no-cache bash'
)

# shellcheck disable=SC2016
apacheFiles='COPY files/vhost.conf $APACHE_CONFDIR/sites-available/000-default.conf\n'
# shellcheck disable=SC2016
apacheFiles+='COPY files/vhost-https.conf $APACHE_CONFDIR/sites-available/default-ssl.conf\n'
# shellcheck disable=SC2016
apacheFiles+='COPY files/ports.conf $APACHE_CONFDIR/ports.conf\n\n'
apacheFiles+='EXPOSE 8080/tcp\n'
apacheFiles+='EXPOSE 8443/tcp\n'

declare -rA files=(
	[apache]=$apacheFiles
	[fpm]=''
	[fpm-alpine]=''
)

cd "$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"

version="$(grep -oP '^ARG YOURLS_VERSION=\"\K[^\"]+' Dockerfile.template)"
sha256="$(curl -fsSL "https://github.com/YOURLS/YOURLS/archive/${version}.tar.gz" | sha256sum | awk '{ print $1 }')"

baseFolder="$1"

for variant in apache fpm fpm-alpine; do
	mkdir -p "$baseFolder$variant"

	cp Dockerfile.template "$baseFolder$variant/Dockerfile"

	sed -ri \
		-e 's/%%VARIANT%%/'"$variant"'/' \
		-e 's/%%VARIANT_EXTRAS%%/'"${extras[$variant]}"'/' \
		-e 's#%%VARIANT_FILES%%#'"${files[$variant]}"'#' \
		-e 's/%%VERSION%%/'"$version"'/' \
		-e 's/%%SHA256%%/'"$sha256"'/' \
		-e 's/%%CMD%%/'"${cmd[$variant]}"'/' \
		"$baseFolder$variant/Dockerfile"

	cp -a container-entrypoint.sh "$baseFolder$variant/container-entrypoint.sh"
	cp -a config-container.php "$baseFolder$variant/config-container.php"

	if [ "$variant" = 'apache' ]; then
		cp -a -r files "$baseFolder$variant/files"
	fi
done
