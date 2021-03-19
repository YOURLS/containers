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

current="$1"
# Using Packagist API
#if [ -z "$current" ]; then
#	current="$(curl -fsSL 'https://packagist.org/p/yourls/yourls.json' | jq -r '.packages["yourls/yourls"]')"
#fi
#sha256="$(curl -fsSL 'https://packagist.org/p/yourls/yourls.json' | jq -r ".packages['yourls/yourls']['${current}'].dist.shasum")"

# Using GitHub API
if [ -z "$current" ]; then
	current="$(curl -fsSL 'https://api.github.com/repos/YOURLS/YOURLS/releases/latest' | jq -r '.tag_name')"
fi
sha256="$(curl -fsSL "https://github.com/YOURLS/YOURLS/archive/${current}.tar.gz" | sha256sum | awk '{ print $1 }')"

base_folder="${2:$2/}"

for variant in apache fpm fpm-alpine; do
	mkdir -p "$base_folder$variant"

	cp Dockerfile.template "$base_folder$variant/Dockerfile"

	sed -ri \
		-e 's/%%VARIANT%%/'"$variant"'/' \
		-e 's/%%VARIANT_EXTRAS%%/'"${extras[$variant]}"'/' \
		-e 's/%%VARIANT_FILES%%/'"${files[$variant]}"'/' \
		-e 's/%%VERSION%%/'"$current"'/' \
		-e 's/%%SHA256%%/'"$sha256"'/' \
		-e 's/%%CMD%%/'"${cmd[$variant]}"'/' \
		"$base_folder$variant/Dockerfile"

	cp -a docker-entrypoint.sh "$base_folder$variant/docker-entrypoint.sh"
	cp -a config-docker.php "$base_folder$variant/config-docker.php"

	if [ "$variant" = 'apache' ]; then
		cp -a yourls.vhost "$base_folder$variant/.htaccess"
	fi

	ciVariants="$variant${ciVariants:+, $ciVariants}"
done

sed -i "s/version:.*/version: [$current]/g" .github/workflows/ci.yml
sed -i "s/variant:.*/variant: [$ciVariants]/g" .github/workflows/ci.yml
