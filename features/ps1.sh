#!/bin/sh

# shellcheck disable=SC3043

# @description Displays a help message if the feature is enabled.
#
# @stderr The error message if the feature is not enabled.
# @stdout The help message if the feature is enabled.
#
# @exitcode 0 If the feature is enabled.
# @exitcode 1 If the feature is not enabled.
__posh_feature_ps1()
{
    if [ "${__POSH_FEATURE_PS1_INIT:-0}" -eq 1 ]; then
        __posh_feature_ps1_help
    else
        __posh_error . "ps1 is not enabled"
    fi
}

# @description Displays a help message for the feature.
__posh_feature_ps1_help()
{
    cat - << HELP >&2
Usage: posh feature ps1 [COMMAND]
Manages control over the ps1 feature.

COMMAND

    help   Displays this help message.
    off    Turns off this feature.
    on     Turns on this feature.

HELP
}

# @description Initializes the feature in a new shell session.
#
# @exitcode 0 If the feature was initialized.
# @exitocde 1 If the feature could not be initialized.
__posh_feature_ps1_init()
{
    # Make sure this feature is not initialized more than once.
    if [ "${__POSH_FEATURE_PS1_INIT:-0}" -eq 1 ]; then
        __posh_debug . "already initialized: ps1"

        return 0
    fi

    # Initialize the feature.
    __posh_debug . "initializing: ps1"

    # Use a shell specific implementation of PS1.
    if [ -n "$BASH_VERSION" ]; then
        PS1="\[\e[90m\][\t]\[\e[0m\] \[\e[32m\]\W\[\e[0m\] \[\e[35m\]\$\[\e[0m\] "
    elif [ -n "$ZSH_VERSION" ]; then
        PS1="%F{8}[%D{%H:%M:%S}]%F{none} %F{green}[%C]%F{none} %F{magenta}$%F{none} "
    else
        __posh_error . "ps1: shell not supported"

        return 1
    fi

    # Remember activation.
    export __POSH_FEATURE_PS1_INIT=1
}

# @description Manages the process of turning the feature off.
#
# @exitcode 0 If the feature was turned off.
# @exitcode 1 If the feature could not be turned off.
__posh_feature_ps1_off()
{
    # Make sure this feature is already on.
    if [ "${__POSH_FEATURE_PS1_INIT:-0}" -eq 0 ]; then
        __posh_debug . "already off: ps1"

        return 0
    fi

    # Clear the initialization flag.
    unset __POSH_FEATURE_PS1_INIT

    __posh_off ps1
}

# @description Manages the process of turning on the feature.
#
# @exitcode 0 If the feature was turned on.
# @exitcode 1 If the feature could not be turned on.
__posh_feature_ps1_on()
{
    # Make sure this feature is not turned on more than once.
    if [ "${__POSH_FEATURE_PS1_INIT:-0}" -eq 1 ]; then
        __posh_debug . "already on: ps1"

        return 0
    fi

    # Initialize the feature.
    if ! __posh_feature_ps1_init; then
        return 1
    fi

    __posh_on ps1
}

