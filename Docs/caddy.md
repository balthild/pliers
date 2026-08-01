# Caddy

The Caddy module lets you define virtual hosts, generate Caddy configuration, and control the Caddy service through systemd.

## Service

From the status bar above the site list, You can start, stop, restart, or reload the Caddy system service.

## Site

The following settings are available for each site:

- Domains
- TLS settings
- Backend settings
- Custom Caddy config section

### Domains

At least one domain is required for a site. Domains must be unique across all sites.

### TLS

- None: the site will be available over HTTP only
- ACME: automatic certificate management
- File: custom certificate and key file paths

### Backend

- None: outputs `It works!` for testing purposes
- Proxy: reverse proxy to an upstream address
- File: serve static files from the specified path
- PHP: serve PHP applications in the specified path through PHP-FPM

## Workflow

The caddy configuration is untouched when you change the site settings. You need to trigger a configuration generation and validation by clicking the "Apply" button. If succeeded, you can then reload the Caddy service to bring the new configuration online.
