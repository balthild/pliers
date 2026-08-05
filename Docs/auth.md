# Authentication

Pliers supports three login methods:

- Token
- Passkey
- Password + TOTP

All login methods are available on the login page at `/login`.

## 1) Token

Token login is designed for local, temporary access. The first login of a user must be with this method, since there's no other way to authenticate initially.

### Usage

1. Run `pliers auth` as the target user.
2. The command will print a token.
3. Paste that value into the Token tab on `/login`.

### Note

Tokens can only be generated while the dashboard service is running.

Once generated, the token will expire in a few minutes. It will also be invalidated after a successful login or when a new token is generated for the same user.

## 2) Passkey

Passkey login uses WebAuthn and modern platform or hardware authenticators.

### Setup

1. Sign in and go to `/settings`.
2. In the Passkey section, choose New Passkey.
3. Provide a display name.
4. Complete the browser/device authenticator prompt.

### Usage

1. Open `/login` and switch to Passkey tab.
2. Click Login with Passkey.
3. Complete the authenticator prompt.

### Management

From `/settings` you can:

- Rename passkeys
- Delete passkeys
- See when the passkey was last used

## Note

Passkeys are tied to a specific host (domain+port). If you change the domain, IP address, or port of Pliers, your previously registered Passkeys will no longer work.

Due to the limitation of some WebAuthn implementations, you may have to use `localhost` rather than `127.0.0.1` when visiting the dashboard locally.

## 3) Password + TOTP

This authentication method is not recommended. Prefer Passkey whenever available.

### Setup

1. Sign in first using token or passkey.
2. Go to the settings page (`/settings`).
4. Input your password and confirmation.
5. Scan the generated TOTP QR code with your authenticator app.
6. Enter the current TOTP code and save.

### Usage

On `/login` in the Password tab, fill:

- Username
- Password
- TOTP

Then submit the form.

### Management

From `/settings` you can:

- Change password
- Remove password + TOTP authentication
