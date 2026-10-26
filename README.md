# Pliers

A web-based dashboard to manage your Linux server.

## Getting Started

[Documentation](./Docs/index.md)

## Development

The following toolchains are required:

- Swift (dev-snapshot)
- Node.js (v20 or later)

### Setup

Refer to the `Makefile` for configurable options.

```bash
make configure
npm clean-install # or `npm ci`
```

`npm clean-install` installs the exact versions pinned in lockfile, so that a clean checkout builds the same frontend dependencies rather than resolving new ones.

### Build and Run in Debug Mode

```bash
make dev.serve # run the dashboard as root
make dev.auth # generate a login token for root
```

### Build the Frontend and Rebuild on Changes

```bash
make dev.vite
```

### Build in Release Mode

```bash
make build
```
