POSH
====

A (mostly) POSIX-compliant shell customization suite.

This is my personal collection of custom shell scripts used to tweak my POSIX-compliant shell environments. As such, they are very opinionated and likely not to change unless it is to fix a bug. I recommend cloning this repository to keep features stable on your end.

> 🤔 **Why mostly?**
>
> There is one non-POSIX feature I use everywhere: `local`. This is to prevent a lot of temporary variables from polluting the namespace and to save a lot of headache in the follow up clean up work. Fortunately, this keyword is implemented in any shell I would likely use: `bash`, `dash`, and `zsh`.

Installation
------------

1. Clone this repository to: `~/.local/opt/posh`
2. Edit your shell configuration file (`.bashrc`, `.zshrc`, etc.):
    ```sh
    # Load my shell customizations.
    export POSH_DIR="$HOME/.local/opt/posh"
    . "$POSH_DIR/posh.sh"; __posh_init
    ```
3. Start a new shell session.
4. Run: `posh`

Usage
-----

When you run `posh`, the help message provides everything you will need.

Features
--------

All of the customizations are implemented as individual scripts in the [features](features/) directory.