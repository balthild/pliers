# File Manager

The File Manager module provides a browser-based interface to inspect and modify filesystem content.

## Core navigation

- Browse directories
- Open files for text editing
- Move up to parent directory with `..`
- View owner and permission for an entry

## File and directory operations

From the current directory, you can perform:

- `Mkdir`: create a new subdirectory
- `Create`: create a new file
- `Upload`: create a new file with uploaded content
- `Edit`: open a text file editor
- `Download`: get the raw content of the file
- `Chmod`: change file mode (unix permissions)
- `Delete`: remove files or directories recursively
- `Unarchive`: extract supported archives into current directory

## Permissions and access checks

Pliers performs file operations as the user you are logged in as. What you have privileges to do on the dashboard will be the same as what you have privileges to do in other ways (e.g. in a desktop file manager, in a terminal, or through an SSH session), which is determined by the Linux permission system.

Special case: anyone will be permitted to operate on the files in the standard web directory managed by Pliers.

## Editing files

Click on any file to open it in the text editor. The editor only supports UTF-8 text files.

## Changing file modes

Accepts 3-digit octal numbers (`000` to `777`). For safety reasons, Sticky/SUID/SGID bits cannot be set on the dashboard.

## Archive extraction

Currently supports zip and tarballs. Extraction runs in the file's parent directory and may overwrite existing files with the same names.
