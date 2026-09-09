# cdb

`cdb` is a small Bash/Zsh utility that lets you assign shortcuts to frequently used directories and jump to them quickly.

It stores up to nine numbered bookmarks, from `1` to `9`, and provides a simple CLI to add, list, clear, print, or use those bookmarks.

## Features

- Save directory aliases as numbered bookmarks
- Jump directly to a saved path with `cdb <number>`
- Add or update a bookmark with `cdb -a <number>:<path>`
- Empty one bookmark or reset all bookmarks
- List bookmarks in plain text or colorized format
- Print the stored path for a bookmark

More information with the `-h` function

## Installation

Run the installer:

```bash
./install.sh
```

This script:

- makes `cdbuffer.sh` executable
- adds the required `source` command to your shell configuration (`.bashrc` or `.zshrc`)
- defines the `cdb` function for interactive use

Then reload your shell:

```bash
source ~/.bashrc
# or
source ~/.zshrc
```

## Example

```bash
cdb -a 1:$HOME/projects/my-app
cdb 1
```

This stores the directory `$HOME/projects/my-app` under macro `1` and moves to it immediately.

## Files

- `cdbuffer.sh`: main command logic
- `cdbuffer`: plain text storage of saved paths
- `cdbuffercolor`: colorized bookmark listing
- `install.sh`: installation script

## Notes

- The command is designed for Bash and Zsh under UNIX. Not compatible with MacOS or Windows
- Bookmarks are numbered from `1` to `9`; there's no `0`.
- A bookmark can be reset to `[None]` if it is empty.
