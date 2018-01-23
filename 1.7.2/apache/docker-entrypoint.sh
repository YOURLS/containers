#!/bin/bash
set -e

if [ ! -e '/var/www/html/yourls-loader.php' ]; then
	tar cf - --one-file-system -C /usr/src/yourls . | tar xf -
	chown -R www-data /var/www/html
fi

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
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

# allow any of these "Authentication Unique Keys and Salts." to be specified via
# environment variables with a "YOURLS_" prefix (ie, "YOURLS_AUTH_KEY")
uniqueEnvs=(
    COOKIEKEY
)
envs=(
    YOURLS_DB_HOST
    YOURLS_DB_USER
    YOURLS_DB_PASS
    YOURLS_DB_NAME
    "${uniqueEnvs[@]/#/YOURLS_}"
    YOURLS_DB_PREFIX
    YOURLS_SITE
)
haveConfig=
for e in "${envs[@]}"; do
    file_env "$e"
    if [ -z "$haveConfig" ] && [ -n "${!e}" ]; then
        haveConfig=1
    fi
done

# linking backwards-compatibility
if [ -n "${!MYSQL_ENV_MYSQL_*}" ]; then
    haveConfig=1
    # host defaults to "mysql" below if unspecified
    : "${YOURLS_DB_USER:=${MYSQL_ENV_MYSQL_USER:-root}}"
    if [ "$YOURLS_DB_USER" = 'root' ]; then
        : "${YOURLS_DB_PASS:=${MYSQL_ENV_MYSQL_ROOT_PASSWORD:-}}"
    else
        : "${YOURLS_DB_PASS:=${MYSQL_ENV_MYSQL_PASSWORD:-}}"
    fi
    : "${YOURLS_DB_NAME:=${MYSQL_ENV_MYSQL_DATABASE:-}}"
fi

for unique in "${uniqueEnvs[@]}"; do
    uniqVar="YOURLS_$unique"
    if [ -z "${!uniqVar}" ]; then
        # if not specified, let's generate a random value
        file_env "$uniqVar" "$(head -c1m /dev/urandom | sha1sum | cut -d' ' -f1)"
    fi
done

# only touch "user/config.php" if we have environment-supplied configuration values
if [ "$haveConfig" ]; then
    : "${YOURLS_DB_HOST:=mysql}"
    : "${YOURLS_DB_USER:=root}"
    : "${YOURLS_DB_PASSWORD:=}"
    : "${YOURLS_DB_NAME:=yourls}"

    if [ ! -e /var/www/html/user/config.php ]; then
        cp /var/www/html/config-docker.php /var/www/html/user/config.php
        chown www-data:www-data /var/www/html/user/config.php
        if [ "${YOURLS_USER}" -a "${YOURLS_PASS}" ]; then
          sed -i "s/  getenv('YOURLS_USER') ? getenv('YOURLS_USER') : 'root' => getenv('YOURLS_PASS') ? getenv('YOURLS_PASS') : 'blah',/  '${YOURLS_USER}' => '${YOURLS_PASS}',/g" /var/www/html/user/config.php
        fi
    fi

    TERM=dumb php -- <<'EOPHP'
<?php
// database might not exist, so let's try creating it (just to be safe)

$stderr = fopen('php://stderr', 'w');

list($host, $socket) = explode(':', getenv('YOURLS_DB_HOST'), 2);
$port = 0;
if (is_numeric($socket)) {
	$port = (int) $socket;
	$socket = null;
}
$user = getenv('YOURLS_DB_USER');
$pass = getenv('YOURLS_DB_PASS');
$dbName = getenv('YOURLS_DB_NAME');

$maxTries = 10;
do {
	$mysql = new mysqli($host, $user, $pass, '', $port, $socket);
	if ($mysql->connect_error) {
		fwrite($stderr, "\n" . 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
		--$maxTries;
		if ($maxTries <= 0) {
			exit(1);
		}
		sleep(3);
	}
} while ($mysql->connect_error);

if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($dbName) . '`')) {
	fwrite($stderr, "\n" . 'MySQL "CREATE DATABASE" Error: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
}

$mysql->close();
EOPHP
fi

exec "$@"
