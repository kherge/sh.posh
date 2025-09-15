#!/bin/sh

# Make sure we get the name of the feature.
if [ -z "$1" ]; then
    cat - << HELP >&2
Usage: $(basename "$0") FEATURE
Scaffolds a new feature for development.

ARGUMENTS

    FEATURE  The name of the feature.

HELP

    exit 1
fi

FEATURE="$1"
FEATURE_UPPER="$(echo "$FEATURE" | tr '[:lower:]' '[:upper:]')"

# Generate the new feature.
cat - << FEATURE > "features/$FEATURE.sh"
#!/bin/sh

# shellcheck disable=SC3043

# @description Displays a help message if the feature is enabled.
#
# @stderr The error message if the feature is not enabled.
# @stdout The help message if the feature is enabled.
#
# @exitcode 0 If the feature is enabled.
# @exitcode 1 If the feature is not enabled.
__posh_feature_${FEATURE}()
{
    if [ "\${__POSH_FEATURE_${FEATURE_UPPER}_INIT:-0}" -eq 1 ]; then
        __posh_feature_${FEATURE}_help
    else
        __posh_error . "$FEATURE is not enabled"
    fi
}

# @description Displays a help message for the feature.
__posh_feature_${FEATURE}_help()
{
    cat - << HELP >&2
Usage: posh feature $FEATURE [COMMAND]
Manages control over the $FEATURE feature.

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
__posh_feature_${FEATURE}_init()
{
    # Make sure this feature is not initialized more than once.
    if [ "\${__POSH_FEATURE_${FEATURE_UPPER}_INIT:-0}" -eq 1 ]; then
        __posh_debug "already initialized: $FEATURE"

        return 0
    else
        export __POSH_FEATURE_${FEATURE_UPPER}_INIT=1
    fi

    # Initialize the feature.
    __posh_debug "initializing: $FEATURE"
}

# @description Manages the process of turning the feature off.
#
# @exitcode 0 If the feature was turned off.
# @exitcode 1 If the feature could not be turned off.
__posh_feature_${FEATURE}_off()
{
    # Make sure this feature is already on.
    if [ "\${__POSH_FEATURE_${FEATURE_UPPER}_INIT:-0}" -eq 0 ]; then
        __posh_debug . "already off: $FEATURE"

        return 0
    fi

    # Clear the initialization flag.
    unset __POSH_FEATURE_${FEATURE_UPPER}_INIT

    __posh_off $FEATURE
}

# @description Manages the process of turning on the feature.
#
# @exitcode 0 If the feature was turned on.
# @exitcode 1 If the feature could not be turned on.
__posh_feature_${FEATURE}_on()
{
    # Make sure this feature is not turned on more than once.
    if [ "\${__POSH_FEATURE_${FEATURE_UPPER}_INIT:-0}" -eq 1 ]; then
        __posh_debug . "already on: $FEATURE"

        return 0
    fi

    # Initialize the feature.
    if ! __posh_feature_${FEATURE}_init; then
        return 1
    fi

    __posh_on $FEATURE
}

FEATURE
