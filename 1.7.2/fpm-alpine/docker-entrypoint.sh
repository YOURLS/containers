#!/bin/bash
set -euo pipefail

if [ ! -e /var/www/html/yourls-loader.php ]; then
	tar cf - --one-file-system -C /usr/src/yourls . | tar xf -
	chown -R www-data:www-data /var/www/html
fi

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
	if [ "$(id -u)" = '0' ]; then
		# if not specified, let's use the default
		: "${YOURLS_DB_USER:=mysql}"
		if [ "$YOURLS_DB_USER" = 'root' ]; then
			: "${YOURLS_DB_PASS:=${MYSQL_ENV_MYSQL_ROOT_PASSWORD:-}}"
		else
			: "${YOURLS_DB_PASS:=${MYSQL_ENV_MYSQL_PASSWORD:-}}"
		fi
		: "${YOURLS_DB_NAME:=yourls}"
		# if not specified, let's generate a random value
		: "${YOURLS_COOKIEKEY:=$(head -c1m /dev/urandom | sha1sum | cut -d' ' -f1)}"

		if [ ! -e /var/www/html/user/config.php ]; then
			cp /var/www/html/config-docker.php /var/www/html/user/config.php
			chown www-data:www-data /var/www/html/user/config.php
		fi

		: "${YOURLS_USER:=}"
		: "${YOURLS_PASS:=}"
		if [ "${YOURLS_USER}" -a "${YOURLS_PASS}" ]; then
			sed -i "s/  getenv('YOURLS_USER') => getenv('YOURLS_PASS'),/  '${YOURLS_USER}' => '${YOURLS_PASS}',/g" /var/www/html/user/config.php
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
