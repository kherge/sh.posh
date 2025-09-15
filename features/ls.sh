#!/bin/sh

# shellcheck disable=SC3043

# @description Displays a help message if the feature is enabled.
#
# @stderr The error message if the feature is not enabled.
# @stdout The help message if the feature is enabled.
#
# @exitcode 0 If the feature is enabled.
# @exitcode 1 If the feature is not enabled.
__posh_feature_ls()
{
    if [ "${__POSH_FEATURE_LS_INIT:-0}" -eq 1 ]; then
        __posh_feature_ls_help
    else
        __posh_error . "ls is not enabled"
    fi
}

# @description Displays a help message for the feature.
__posh_feature_ls_help()
{
    cat - << HELP >&2
Usage: posh ls [COMMAND]
Manages control over the ls feature.

COMMAND

    help   Displays this help message.
    off    Turns off this feature.
    on     Turns on this feature.

How to Use

    Three new command aliases become available after this feature has been
    turned on. When the feature is turned off, these aliases are removed.

        ll

    This alias will display one entry per line and in color. On GNU systems,
    directories are grouped first, control characters are hidden, and the long
    ISO format is used for dates and times.

        la

    An extension of \`ll\` that includes hidden files and folders.

        lh

    An extension of \`ll\` that displays sizes using human readable notation.

HELP
}

# @description Initializes the feature in a new shell session.
#
# @exitcode 0 If the feature was initialized.
# @exitocde 1 If the feature could not be initialized.
__posh_feature_ls_init()
{
    # Make sure this feature is not initialized more than once.
    if [ "${__POSH_FEATURE_LS_INIT:-0}" -eq 1 ]; then
        __posh_debug "already initialized: ls"

        return 0
    else
        export __POSH_FEATURE_LS_INIT=1
    fi

    # Initialize the feature.
    __posh_debug "initializing: ls"

    # Are we using the BSD version?
    if ! ls --help > /dev/null 2>&1; then
        __posh_debug "using BSD version of ls"

        alias ll="ls -G -l"

    # Are we using the GNU version?
    else
        __posh_debug "using GNU version of ls"

        alias ll="ls --color=auto --group-directories-first --hide-control-chars --time-style=long-iso -l"
    fi

    # Create other handy aliases.
    alias la="ll -a"
    alias lh="ll -h"
}

# @description Manages the process of turning the feature off.
#
# @exitcode 0 If the feature was turned off.
# @exitcode 1 If the feature could not be turned off.
__posh_feature_ls_off()
{
    # Make sure this feature is already on.
    if [ "${__POSH_FEATURE_LS_INIT:-0}" -eq 0 ]; then
        __posh_debug . "already off: ls"

        return 0
    fi

    # Clear the initialization flag.
    unset __POSH_FEATURE_LS_INIT
    unalias la
    unalias lh
    unalias ll

    __posh_off ls
}

# @description Manages the process of turning on the feature.
#
# @exitcode 0 If the feature was turned on.
# @exitcode 1 If the feature could not be turned on.
__posh_feature_ls_on()
{
    # Make sure this feature is not turned on more than once.
    if [ "${__POSH_FEATURE_LS_INIT:-0}" -eq 1 ]; then
        __posh_debug . "already on: ls"

        return 0
    fi

    # Initialize the feature.
    if ! __posh_feature_ls_init; then
        return 1
    fi

    __posh_on ls
}

