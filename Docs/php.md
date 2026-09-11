# PHP

The PHP module lets you install PHP runtimes, generate PHP-FPM configuration, and control the PHP-FPM service through systemd.

Each installed PHP version has its own configuration, unix socket, and systemd unit (`pliers-php-<version>.service`), so multiple versions can run side by side.

## Installation

From the PHP list page you can install any PHP version offered by [static-php](https://static-php.dev). Both the `fpm` and `cli` SAPIs are installed under `/opt/pliers/php/<version>`.

## Settings

Click a version, or the "Settings" link, to open its configuration page. The following settings are available:

- Listen: a unix socket or a TCP address
- Process manager and pool sizing
- PHP runtime settings (generated into a separate `php.ini`)

The pool always runs as `www-data`.

### Listen

A unix socket is used by default, at the fixed path `/run/pliers/php/<version>/php-fpm.sock`. The socket is owned by `www-data` with mode `0660` so that the web server can connect to it. Alternatively you can listen on a TCP address such as `127.0.0.1:9000`.

### Pool

- `pm`: `dynamic`, `static`, or `ondemand`
- `max_children`
- `start_servers`, `min_spare_servers`, `max_spare_servers` (only emitted for `dynamic`)
- `max_requests`
- `request_terminate_timeout`

### PHP runtime settings

The following are written to a generated `php.ini` rather than the pool configuration:

- `memory_limit`
- `upload_max_filesize`
- `post_max_size`
- `max_execution_time`

## Service

From the status bar on the settings page, you can start, stop, restart, or reload the PHP-FPM service for that version.

## Workflow

The following files are generated for each version:

- `/etc/pliers/php/<version>/php-fpm.conf`
- `/etc/pliers/php/<version>/php.ini`
- `/etc/systemd/system/pliers-php-<version>.service`

Clicking "Save" persists the settings, regenerates the configuration, validates it with `php-fpm --test`, atomically swaps the live configuration, writes the systemd unit, and reloads the systemd manager. You can then start or restart the service to bring the new configuration online.

Removing a PHP version deletes the package, its configuration, and its systemd unit.
