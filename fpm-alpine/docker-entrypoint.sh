#!/bin/bash
set -euo pipefail

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		printf 'Both %s and %s are set (but are exclusive)' "$var" "$fileVar"
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

file_env 'YOURLS_DB_HOST'
file_env 'YOURLS_DB_USER'
file_env 'YOURLS_DB_PASS'
file_env 'YOURLS_DB_NAME'
file_env 'YOURLS_DB_PREFIX'
file_env 'YOURLS_SITE'
file_env 'YOURLS_USER'
file_env 'YOURLS_PASS'

if [ ! -e /var/www/html/yourls-loader.php ]; then
	tar cf - --one-file-system -C /usr/src/yourls . | tar xf -
	chown -R www-data:www-data /var/www/html
fi

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
	if [ "$(id -u)" = '0' ]; then
		# if not specified, let's generate a random value
		: "${YOURLS_COOKIEKEY:=$(head -c1m /dev/urandom | sha1sum | cut -d' ' -f1)}"

		# We want to copy the initial config if the actual config file doesn't already
		# exist OR if it is an empty file (e.g. it has been created for the volume mount).
		if [ ! -e /var/www/html/user/config.php ] || [ ! -s /var/www/html/user/config.php ]; then
			cp /var/www/html/user/config-docker.php /var/www/html/user/config.php
			chown www-data:www-data /var/www/html/user/config.php
		fi

		: "${YOURLS_USER:=}"
		: "${YOURLS_PASS:=}"
		if [ -n "${YOURLS_USER}" ] && [ -n "${YOURLS_PASS}" ]; then
			result=$(sed "s/  getenv('YOURLS_USER') => getenv('YOURLS_PASS'),/  \'${YOURLS_USER}\' => \'${YOURLS_PASS}\',/g" /var/www/html/user/config.php)
			echo "$result" > /var/www/html/user/config.php
		fi

		TERM=dumb php -- <<'EOPHP'
<?php
// database might not exist, so let's try creating it (just to be safe)

$stderr = fopen('php://stderr', 'w');

require '/var/www/html/user/config.php';

list($host, $socket) = explode(':', YOURLS_DB_HOST, 2);
$port = 0;
if (is_numeric($socket)) {
	$port = (int) $socket;
	$socket = null;
}

$maxTries = 10;
do {
	$mysql = new mysqli($host, YOURLS_DB_USER, YOURLS_DB_PASS, '', $port, $socket);
	if ($mysql->connect_error) {
		fwrite($stderr, "\nMySQL Connection Error: ({$mysql->connect_errno}) {$mysql->connect_error}\n");
		--$maxTries;
		if ($maxTries <= 0) {
			exit(1);
		}
		sleep(3);
	}
} while ($mysql->connect_error);

if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `'.$mysql->real_escape_string(YOURLS_DB_NAME).'`')) {
	fwrite($stderr, "\nMySQL \"CREATE DATABASE\" Error: {$mysql->error}\n");
	$mysql->close();
	exit(1);
}

$mysql->close();
EOPHP
	fi
fi

exec "$@"
