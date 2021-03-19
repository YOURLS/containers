#!/bin/bash
set -eu

# shellcheck source=functions.sh
source "${BASH_SOURCE[0]%/*}/functions.sh"

self="bin/$(basename "${BASH_SOURCE[0]}")"
cd "$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"

getArches 'yourls'

cat <<-EOH
# this file is generated via https://github.com/YOURLS/docker-yourls/blob/$(fileCommit "$self")/$self

Maintainers: YOURLS <yourls@yourls.org> (@YOURLS),
             Léo Colombaro <git@colombaro.fr> (@LeoColomb)
GitRepo: https://github.com/YOURLS/docker-yourls.git
GitFetch: refs/heads/dist
EOH

for variant in apache fpm fpm-alpine; do
	commit="$(dirCommit "$variant")"
	variantAliases=$(./bin/generate-aliases.sh "$variant")

	variantParent="$(awk 'toupper($1) == "FROM" { print $2 }' "$variant/Dockerfile")"
	# shellcheck disable=SC2154
	variantArches="${parentRepoToArches[$variantParent]}"

	echo
	cat <<-EOE
		Tags: $variantAliases
		Architectures: $(join ', ' $variantArches)
		GitCommit: $commit
		Directory: $variant
	EOE
done
