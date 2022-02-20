#!/bin/bash
set -e

# shellcheck source=functions.sh
source "${BASH_SOURCE[0]%/*}/functions.sh"

version="$1"
variant="$2"

versionAliases=()
while [ "${version%[.-]*}" != "$version" ]; do
	versionAliases+=( "$version" )
	version="${version%[.-]*}"
done
versionAliases+=(
	"$version"
	latest
)

variantAliases=( "${versionAliases[@]/%/-$variant}" )
variantAliases=( "${variantAliases[@]//latest-/}" )

if [ "$variant" = 'apache' ]; then
	variantAliases+=( "${versionAliases[@]}" )
fi

if [ -n "$2" ]; then
	variantAliases=( "${variantAliases[@]/#/$3:}" )
fi

echo "$(join ', ' "${variantAliases[@]}")"
