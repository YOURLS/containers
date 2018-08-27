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
	[apache]='COPY .htaccess \/var\/www\/html\/'
	[fpm]=''
	[fpm-alpine]=''
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

#current="$(curl -fsSL 'https://packagist.org/p/yourls/yourls.json' | jq -r '?')"
current="$(curl -fsSL 'https://api.github.com/repos/YOURLS/YOURLS/releases' | jq -r '.[0].tag_name')"

travisEnv=
for variant in apache fpm fpm-alpine; do
    mkdir -p "$current/$variant"

    cp Dockerfile.template "$current/$variant/Dockerfile"

    sed -ri \
        -e 's/%%VARIANT%%/'"$variant"'/' \
        -e 's/%%VARIANT_EXTRAS%%/'"${extras[$variant]}"'/' \
        -e 's/%%VARIANT_FILES%%/'"${files[$variant]}"'/' \
        -e 's/%%VERSION%%/'"$current"'/' \
        -e 's/%%CMD%%/'"${cmd[$variant]}"'/' \
        "$current/$variant/Dockerfile"

    cp -a docker-entrypoint.sh "$current/$variant/docker-entrypoint.sh"
    cp -a config-docker.php "$current/$variant/config-docker.php"

    if [ "$variant" = 'apache' ]; then
        cp -a yourls.vhost "$current/$variant/.htaccess"
    fi

    travisEnv='\n  - VERSION='"$current"' VARIANT='"$variant$travisEnv"
    
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
