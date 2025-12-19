<?php

// Local WordPress configuration for gaycarboys.com clone.

define('DB_NAME', getenv('DB_NAME') ?: 'gaycarboys');
define('DB_USER', getenv('DB_USER') ?: 'gaycarboys');
define('DB_PASSWORD', getenv('DB_PASSWORD') ?: 'gaycarboys');
define('DB_HOST', getenv('WORDPRESS_DB_HOST') ?: 'db:3306');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

$table_prefix = getenv('DB_TABLE_PREFIX') ?: 'wp_';

// Debug settings - show errors but hide notices/warnings for cleaner frontend
define('WP_DEBUG', getenv('WP_DEBUG') !== 'false');
define('WP_DEBUG_DISPLAY', false); // Don't show errors on frontend
define('WP_DEBUG_LOG', true); // Log errors to wp-content/debug.log instead
define('SCRIPT_DEBUG', false);

// Suppress PHP notices, warnings, and deprecated messages (but keep errors)
if (WP_DEBUG) {
    // Only show fatal errors, suppress notices/warnings/deprecated
    error_reporting(E_ERROR | E_PARSE);
    @ini_set('display_errors', 0);
    @ini_set('display_startup_errors', 0);
}

if (getenv('WP_HOME')) {
    define('WP_HOME', getenv('WP_HOME'));
}

if (getenv('WP_SITEURL')) {
    define('WP_SITEURL', getenv('WP_SITEURL'));
}

// Local-only salts/keys – you can regenerate these anytime for local.
define('AUTH_KEY',         'local-auth-key-change-me');
define('SECURE_AUTH_KEY',  'local-secure-auth-key-change-me');
define('LOGGED_IN_KEY',    'local-logged-in-key-change-me');
define('NONCE_KEY',        'local-nonce-key-change-me');
define('AUTH_SALT',        'local-auth-salt-change-me');
define('SECURE_AUTH_SALT', 'local-secure-auth-salt-change-me');
define('LOGGED_IN_SALT',   'local-logged-in-salt-change-me');
define('NONCE_SALT',       'local-nonce-salt-change-me');

// Allow file mods in local for theme/plugin development.
define('FS_METHOD', 'direct');

// Absolute path to the WordPress directory.
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/../wordpress/');
}

require_once ABSPATH . 'wp-settings.php';


