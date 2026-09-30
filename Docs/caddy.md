# Caddy

The Caddy module lets you define virtual hosts, generate Caddy configuration, and control the Caddy service through systemd.

## Service

From the status bar above the site list, You can start, stop, restart, or reload the Caddy system service.

## Site

The following settings are available for each site:

- Domains
- TLS settings
- Backend settings
- Compression
- Caching
- CORS
- Logging
- Trusted proxies (proxy backend only)
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

### Compression

- Enable: emit an `encode` directive
- Customize: choose the encodings and their options explicitly
  - Gzip: enable and optionally set the level (1-9)
  - Zstd: enable and optionally set the level (`default`, `fastest`, `better`, `best`)
  - Minimum length: skip responses shorter than this many bytes

When "Customize" is off (or no encoding is selected), a plain `encode` directive is emitted,
which enables Caddy's default encodings.

### Caching

Adds a `Cache-Control` response header.

- Max age: the `max-age` value in seconds (defaults to 3600)
- Visibility: `public` or `private`
- Immutable: add the `immutable` directive

### CORS

Generates the `Access-Control-*` response headers and answers preflight (`OPTIONS`) requests
directly with `204 No Content`.

- Origins: `*` for any origin, or one allowed origin per line
- Methods / Headers: comma-separated values sent in the respective headers
- Credentials: allow credentials (cannot be combined with a `*` origin)
- Max age: the `Access-Control-Max-Age` value in seconds

When specific origins are configured, each origin gets its own matcher so that the matching
origin is echoed in `Access-Control-Allow-Origin`, and `Vary: Origin` is set.

### Logging

Enables the `log` directive (HTTP access logs).

- Output: the path to the log file; leave blank to use `/var/log/caddy/<site-id>.log`
- Format: `console` or `json`

Directories under the Caddy log directory are created automatically and owned by the Caddy user.

### Trusted proxies

Only available for the proxy backend, because Caddy only honours `trusted_proxies` inside
`reverse_proxy`. The selected ranges are emitted as a `trusted_proxies` line inside the proxy block.

- Docker Network: trust Docker's default bridge range (`172.16.0.0/12`)
- Cloudflare: trust Cloudflare's published IP ranges. The list is refreshed in the background
  once an hour while the dashboard is running, and the latest snapshot is used when the
  configuration is generated
- Custom: one IP address or CIDR range per line


## Workflow

The caddy configuration is untouched when you change the site settings. You need to trigger a configuration generation and validation by clicking the "Apply" button. If succeeded, you can then reload the Caddy service to bring the new configuration online.
