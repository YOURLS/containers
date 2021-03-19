#!/bin/bash
set -e

# shellcheck source=functions.sh
source "${BASH_SOURCE[0]%/*}/functions.sh"

variant="$1"
commit="$(dirCommit "$variant")"

fullVersion="$(git show "${commit}:${variant}/Dockerfile" | awk '$1 == "ENV" && $2 == "YOURLS_VERSION" { print $3; exit }')"

versionAliases=()
while [ "${fullVersion%[.-]*}" != "$fullVersion" ]; do
	versionAliases+=( "$fullVersion" )
	fullVersion="${fullVersion%[.-]*}"
done
versionAliases+=(
	"$fullVersion"
	latest
)

variantAliases=( "${versionAliases[@]/%/-$variant}" )
variantAliases=( "${variantAliases[@]//latest-/}" )

if [ "$variant" = 'apache' ]; then
	variantAliases+=( "${versionAliases[@]}" )
fi

if [ -n "$2" ]; then
	variantAliases=( "${variantAliases[@]/#/$2:}" )
fi

echo "$(join ', ' "${variantAliases[@]}")"
