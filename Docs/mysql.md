# MySQL

## Service

From the status bar above the page, you can start, stop, restart, or reload the
MySQL system service through systemd.

## Databases

Pliers manages MySQL databases that it created itself — it never shows or touches
databases created outside the panel.

Every database is paired with exactly one user: creating a database also creates its
user and grants that user full privileges on the database, and deleting the database
drops the user with it. Standalone users cannot be created.

Each panel user sees only the databases they created. Administrators can pick a
different owner from the dropdown to view and manage that user's databases.

### Host

Every user is created for a specific host: `localhost` allows connections from this
server only, while `%` allows connections from any host. Any other host may be entered
by hand.

### Password

The password is sent to MySQL when the database is created and is never stored by
Pliers. To change it later, open the database and enter a new password; leaving the
field blank keeps the current password.

Deleting a database drops the database and its user on the MySQL server and cannot be
undone.
