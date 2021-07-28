#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$1" == apache2* ]] || [ "$1" = 'php-fpm' ]; then
	uid="$(id -u)"
	gid="$(id -g)"
	if [ "$uid" = '0' ]; then
		case "$1" in
		apache2*)
			user="${APACHE_RUN_USER:-www-data}"
			group="${APACHE_RUN_GROUP:-www-data}"

			# strip off any '#' symbol ('#1000' is valid syntax for Apache)
			pound='#'
			user="${user#$pound}"
			group="${group#$pound}"
			;;
		*) # php-fpm
			user='www-data'
			group='www-data'
			;;
		esac
	else
		user="$uid"
		group="$gid"
	fi

	if [ ! -e yourls-loader.php ]; then
		# if the directory exists and YOURLS doesn't appear to be installed AND the permissions of it are root:root, let's chown it (likely a Docker-created directory)
		if [ "$uid" = '0' ] && [ "$(stat -c '%u:%g' .)" = '0:0' ]; then
			chown "$user:$group" .
		fi

		echo >&2 "YOURLS not found in $PWD - copying now..."
		if [ -n "$(find . -mindepth 1 -maxdepth 1 -not -name user)" ]; then
			echo >&2 "WARNING: $PWD is not empty! (copying anyhow)"
		fi
		sourceTarArgs=(
			--create
			--file -
			--directory /usr/src/yourls
			--owner "$user" --group "$group"
		)
		targetTarArgs=(
			--extract
			--file -
		)
		if [ "$uid" != '0' ]; then
			# avoid "tar: .: Cannot utime: Operation not permitted" and "tar: .: Cannot change mode to rwxr-xr-x: Operation not permitted"
			targetTarArgs+=(--no-overwrite-dir)
		fi
		# loop over "pluggable" content in the source, and if it already exists in the destination, skip it
		for contentPath in \
			/usr/src/yourls/.htaccess \
			/usr/src/yourls/user/*/*/ \
		; do
			contentPath="${contentPath%/}"
			[ -e "$contentPath" ] || continue
			contentPath="${contentPath#/usr/src/yourls/}" # "user/plugins/plugin-name", etc.
			if [ -e "$PWD/$contentPath" ]; then
				echo >&2 "WARNING: '$PWD/$contentPath' exists! (not copying the YOURLS version)"
				sourceTarArgs+=(--exclude "./$contentPath")
			fi
		done
		tar "${sourceTarArgs[@]}" . | tar "${targetTarArgs[@]}"
		echo >&2 "Complete! YOURLS has been successfully copied to $PWD"
	fi

	# if not specified, let's generate a random value
	: "${YOURLS_COOKIEKEY:=$(head -c1m /dev/urandom | sha1sum | cut -d' ' -f1)}"

	# We want to copy the initial config if the actual config file doesn't already
	# exist OR if it is an empty file (e.g. it has been created for the volume mount).
	if [ ! -s user/config.php ]; then
		cp /usr/src/yourls/user/config-docker.php user/config.php

		: "${YOURLS_USER:=}"
		: "${YOURLS_PASS:=}"
		if [ -n "${YOURLS_USER}" ] && [ -n "${YOURLS_PASS}" ]; then
			result=$(sed "s/  getenv_docker('YOURLS_USER') => getenv_docker('YOURLS_PASS'),/  \'${YOURLS_USER}\' => \'${YOURLS_PASS}\',/g" user/config.php)
			echo "$result" > user/config.php
		fi

		if [ "$uid" = '0' ]; then
			# attempt to ensure that wp-config.php is owned by the run user
			# could be on a filesystem that doesn't allow chown (like some NFS setups)
			chown "$user:$group" wp-config.php || true
		fi
	fi
fi

exec "$@"
