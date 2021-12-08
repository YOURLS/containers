<?php
/* This is a sample config file.
 * Edit this file with your own settings and save it as "config.php"
 */

// a helper function to lookup "env_FILE", "env", then fallback
if (!function_exists('getenv_docker')) {
    function getenv_docker(string $name, ?string $default = null): ?string
    {
        if ($fileEnv = getenv($name . '_FILE')) {
            return trim(file_get_contents($fileEnv));
        }
        if (($value = getenv($name)) !== false) {
            return $value;
        }

        return $default;
    }
}

/*
 ** MySQL settings - You can get this info from your web host
 */

/** MySQL database username */
define( 'YOURLS_DB_USER', getenv_docker('YOURLS_DB_USER', 'root') );

/** MySQL database password */
define( 'YOURLS_DB_PASS', getenv_docker('YOURLS_DB_PASS') );

/** The name of the database for YOURLS */
define( 'YOURLS_DB_NAME', getenv_docker('YOURLS_DB_NAME', 'yourls') );

/** MySQL hostname.
 ** If using a non standard port, specify it like 'hostname:port', eg. 'localhost:9999' or '127.0.0.1:666' */
define( 'YOURLS_DB_HOST', getenv_docker('YOURLS_DB_HOST', 'mysql') );

/** MySQL tables prefix */
define( 'YOURLS_DB_PREFIX', getenv_docker('YOURLS_DB_PREFIX', 'yourls_') );

/*
 ** Site options
 */

/** YOURLS installation URL -- all lowercase, no trailing slash at the end.
 ** If you define it to "http://sho.rt", don't use "http://www.sho.rt" in your browser (and vice-versa) */
define( 'YOURLS_SITE', getenv_docker('YOURLS_SITE', 'http://your-own-domain-here.com') );

/** Server timezone GMT offset */
define( 'YOURLS_HOURS_OFFSET', filter_var(getenv('YOURLS_HOURS_OFFSET'), FILTER_VALIDATE_INT) ?: 0 );

/** YOURLS language
 ** Change this setting to use a translation file for your language, instead of the default English.
 ** That translation file (a .mo file) must be installed in the user/language directory.
 ** See http://yourls.org/translations for more information */
define( 'YOURLS_LANG', getenv('YOURLS_LANG') ?: '' );

/** Allow multiple short URLs for a same long URL
 ** Set to true to have only one pair of shortURL/longURL (default YOURLS behavior)
 ** Set to false to allow multiple short URLs pointing to the same long URL (bit.ly behavior) */
define( 'YOURLS_UNIQUE_URLS', getenv('YOURLS_UNIQUE_URLS') === false ?: filter_var(getenv('YOURLS_UNIQUE_URLS'), FILTER_VALIDATE_BOOLEAN) );

/** Private means the Admin area will be protected with login/pass as defined below.
 ** Set to false for public usage (eg on a restricted intranet or for test setups)
 ** Read http://yourls.org/privatepublic for more details if you're unsure */
define( 'YOURLS_PRIVATE', getenv('YOURLS_PRIVATE') === false ?: filter_var(getenv('YOURLS_PRIVATE'), FILTER_VALIDATE_BOOLEAN) );

/** A random secret hash used to encrypt cookies. You don't have to remember it, make it long and complicated. Hint: copy from http://yourls.org/cookie **/
define( 'YOURLS_COOKIEKEY', getenv('YOURLS_COOKIEKEY') ?: 'modify this text with something random' );

/** Username(s) and password(s) allowed to access the site. Passwords either in plain text or as encrypted hashes
 ** YOURLS will auto encrypt plain text passwords in this file
 ** Read http://yourls.org/userpassword for more information */
$yourls_user_passwords = [
    getenv_docker('YOURLS_USER') => getenv_docker('YOURLS_PASS'),
];

/** Debug mode to output some internal information
 ** Default is false for live site. Enable when coding or before submitting a new issue */
define( 'YOURLS_DEBUG', filter_var(getenv('YOURLS_DEBUG'), FILTER_VALIDATE_BOOLEAN) );

/*
** URL Shortening settings
*/

/** URL shortening method: 36 or 62 */
define( 'YOURLS_URL_CONVERT', filter_var(getenv('YOURLS_URL_CONVERT'), FILTER_VALIDATE_INT) ?: 36 );
/*
 * 36: generates all lowercase keywords (ie: 13jkm)
 * 62: generates mixed case keywords (ie: 13jKm or 13JKm)
 * Stick to one setting. It's best not to change after you've started creating links.
 */

/** if set to true, disable stat logging (no use for it, too busy servers, ...) */
define( 'YOURLS_NOSTATS', filter_var(getenv('YOURLS_NOSTATS'), FILTER_VALIDATE_BOOLEAN) );

/**
 * Reserved keywords (so that generated URLs won't match them)
 * Define here negative, unwanted or potentially misleading keywords.
 */
$yourls_reserved_URL = [
    'porn', 'faggot', 'sex', 'nigger', 'fuck', 'cunt', 'dick',
];

/*
 ** Personal settings would go after here.
 */
