#!/bin/bash
set -e

declare -A cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
	[fpm-alpine]='php-fpm'
)

declare -A extras=(
	[apache]='\nRUN a2enmod rewrite expires'
	[fpm]=''
	[fpm-alpine]='\nRUN apk add --no-cache bash'
)

declare -A files=(
	[apache]='COPY .htaccess \/usr\/src\/yourls\/'
	[fpm]=''
	[fpm-alpine]=''
)

cd "$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"

version="$(head -n 1 yourls_version)"
# Using Packagist API
#if [ -z "$version" ]; then
#	version="$(curl -fsSL 'https://packagist.org/p/yourls/yourls.json' | jq -r '.packages["yourls/yourls"]')"
#fi
#sha256="$(curl -fsSL 'https://packagist.org/p/yourls/yourls.json' | jq -r ".packages['yourls/yourls']['${version}'].dist.shasum")"

# Using GitHub API
if [ -z "$version" ]; then
	version="$(curl -fsSL 'https://api.github.com/repos/YOURLS/YOURLS/releases/latest' | jq -r '.tag_name')"
fi
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

	cp -a docker-entrypoint.sh "$baseFolder$variant/docker-entrypoint.sh"
	cp -a config-docker.php "$baseFolder$variant/config-docker.php"

	if [ "$variant" = 'apache' ]; then
		cp -a yourls.vhost "$baseFolder$variant/.htaccess"
	fi

	ciVariants="$variant${ciVariants:+, $ciVariants}"
done
