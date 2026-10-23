# MySQL

## Service

From the status bar above the page, you can start, stop, restart, or reload the
MySQL system service through systemd.

## Accounts

Pliers manages MySQL accounts that it created itself — it never shows or touches
accounts created outside the panel.

Each panel user sees only the accounts they created. Administrators can pick a
different owner from the dropdown to view and manage that user's accounts.

### Limits

Pliers only creates, drops, and resets passwords for accounts. Granting privileges
on databases is not part of this module yet, so a freshly created account has none.

### Host

Every account is created for a specific host: `localhost` allows connections from
this server only, while `%` allows connections from any host. Any other host may be
entered by hand.

### Password

The password is sent to MySQL when the account is created and is never stored by
Pliers. To change it later, open the account and enter a new password; leaving the
field blank keeps the current password.

Deleting an account drops it on the MySQL server and cannot be undone.
