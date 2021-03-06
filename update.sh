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

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# Using Packagist API
#current="$(curl -fsSL 'https://packagist.org/p/yourls/yourls.json' | jq -r '.packages["yourls/yourls"]')"
#sha256="$(curl -fsSL 'https://packagist.org/p/yourls/yourls.json' | jq -r ".packages['yourls/yourls']['${current}'].dist.shasum")"

# Using GitHub API
current="$(curl -fsSL 'https://api.github.com/repos/YOURLS/YOURLS/releases/latest' | jq -r '.tag_name')"
sha256="$(curl -fsSL "https://github.com/YOURLS/YOURLS/archive/${current}.tar.gz" | sha256sum | awk '{ print $1 }')"

for variant in apache fpm fpm-alpine; do
	mkdir -p "$variant"

	cp Dockerfile.template "$variant/Dockerfile"

	sed -ri \
		-e 's/%%VARIANT%%/'"$variant"'/' \
		-e 's/%%VARIANT_EXTRAS%%/'"${extras[$variant]}"'/' \
		-e 's/%%VARIANT_FILES%%/'"${files[$variant]}"'/' \
		-e 's/%%VERSION%%/'"$current"'/' \
		-e 's/%%SHA256%%/'"$sha256"'/' \
		-e 's/%%CMD%%/'"${cmd[$variant]}"'/' \
		"$variant/Dockerfile"

	cp -a docker-entrypoint.sh "$variant/docker-entrypoint.sh"
	cp -a config-docker.php "$variant/config-docker.php"

	if [ "$variant" = 'apache' ]; then
		cp -a yourls.vhost "$variant/.htaccess"
	fi

	ciVariants="$variant${ciVariants:+, $ciVariants}"
done

sed -i "s/version:.*/version: [$current]/g" .github/workflows/ci.yml
sed -i "s/variant:.*/variant: [$ciVariants]/g" .github/workflows/ci.yml
