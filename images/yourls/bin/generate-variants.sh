#!/bin/bash
set -e

declare -A cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
	[fpm-alpine]='php-fpm'
)

declare -A extras=(
	[apache]='RUN a2enmod rewrite expires;\n\nRUN sed -i --follow-symlinks '\''s\/ServerSignature On\/ServerSignature Off\/'\'' \/etc\/apache2\/conf-enabled\/security.conf; \\\n    sed -i --follow-symlinks '\''s\/ServerTokens OS\/ServerTokens Prod\/'\'' \/etc\/apache2\/conf-enabled\/security.conf;'
	[fpm]=''
	[fpm-alpine]='RUN apk add --no-cache bash'
)

declare -A files=(
	[apache]='COPY .htaccess \/usr\/src\/yourls\/'
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
		-e 's/%%VARIANT_FILES%%/'"${files[$variant]}"'/' \
		-e 's/%%VERSION%%/'"$version"'/' \
		-e 's/%%SHA256%%/'"$sha256"'/' \
		-e 's/%%CMD%%/'"${cmd[$variant]}"'/' \
		"$baseFolder$variant/Dockerfile"

	cp -a container-entrypoint.sh "$baseFolder$variant/container-entrypoint.sh"
	cp -a config-container.php "$baseFolder$variant/config-container.php"

	if [ "$variant" = 'apache' ]; then
		cp -a yourls.vhost "$baseFolder$variant/.htaccess"
	fi
done
