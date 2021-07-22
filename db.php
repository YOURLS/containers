<?php
/*
Plugin Name: Secure MySQL
Plugin URI: https://github.com/YOURLS/YOURLS/issues/2783
Description: SSL/TLS PDO Connection
Version: 1.0
Author: YOURLS
Author URI: https://yourls.org/
*/
// No direct call
if( !defined( 'YOURLS_ABSPATH' ) ) die();

// Add custom cert
yourls_add_filter( 'db_connect_driver_option', function ( $options ) {
    // Add your certificate paths
    // https://secure.php.net/manual/ref.pdo-mysql.php
    return $options + [PDO::MYSQL_ATTR_SSL_CA=> "/etc/ssl/certs/db-ca.crt",];
} );

// Load DB layer as usual
require_once YOURLS_INC.'/class-mysql.php';
yourls_db_connect();
