#!/bin/sh

# shellcheck disable=SC1090
# shellcheck disable=SC3043

# Make sure that POSH_DIR is defined.
if [ -z "$POSH_DIR" ]; then
    echo "posh: POSH_DIR must be defined" >&2

    return 1
elif [ ! -f "$POSH_DIR/posh.sh" ]; then
    echo "posh: POSH_DIR must be the POSH directory" >&2

    return 1
fi

# The configuration directory.
__POSH_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/posh"

# The features directory.
__POSH_FEATURES="$POSH_DIR/features"

# The features that have been loaded.
__POSH_LOADED=

# The global indent level for log messages.
__POSH_LOG_INDENT=0

# @description Prints to STDERR if debugging is enabled.
#
# @param $1 The code to change the indent level.
# @param $@ The arguments to print.
#
# @stderr The arguments that were provided.
#
# @see __posh_log()
if [ "${POSH_DEBUG:-0}" -eq 1 ]; then
    __posh_debug()
    {
        local INDENT="$1"; shift

        set -- "$INDENT" '[DEBUG] posh:' "$@"

        __posh_log "$@"
    }
else
    __posh_debug()
    {
        : # no-op
    }
fi

# @description Prints to STDERR.
#
# @param $1 The code to change the indent level.
# @param $@ The arguments to print.
#
# @stderr The arguments that were provided.
#
# @see __posh_log()
__posh_error()
{
    local INDENT="$1"; shift
    local PREFIX='posh:'

    if [ "${POSH_DEBUG:-0}" -eq 1 ]; then
        PREFIX='[ERROR] posh:'
    fi

    set -- "$INDENT" "$PREFIX" "$@"

    __posh_log "$@"
}

# @description Prints the value of a feature configuration setting.
#
# If a value has been set for the configuration setting, it will be printed
# to STDOUT. If no value has been set, nothing will be printed and it will
# not be treated as an error.
#
# @arg $1 The name of the feature.
# @arg $2 The name of the setting.
#
# @exitcode 0 If the value was printed or no value was available.
# @exitcode 1 If the setting could not be read from its file.
__posh_get()
{
    local FEATURE="$1"
    local SETTING="$2"
    local FILE="$__POSH_CONFIG/$FEATURE/$SETTING"

    __posh_debug + "reading $FILE"

    if [ -f "$FILE" ] && ! cat "$FILE"; then
        __posh_error - "could not read: $FILE"

        return 1
    fi

    __posh_debug -
}

# @description Initializes all features that have been turned on.
#
# This function is only called when a new shell session is started. On call,
# the function will iterate through the ordered (by priority) list of features,
# load them, and then invoke their respective initialization function.
#
# @exitcode 0 If all features were successfully initialized.
# @exitcode 1 If one or more features could not be initialized.
__posh_init()
{
    local FEATURE=
    local FEATURES="$__POSH_CONFIG/posh/features"
    local STATUS=0

    # Load any features that have been turned on.
    if [ -f "$FEATURES" ]; then
        __posh_debug + "initializing shell"

        while read -r FEATURE; do
            FEATURE="$(echo "$FEATURE" | cut -d\| -f2)"

            if __posh_load "$FEATURE"; then
                if ! "__posh_feature_${FEATURE}_init"; then
                    STATUS=1

                    __posh_error . "could not be initialized: $FEATURE"
                fi
            fi
        done < "$FEATURES"
    fi

    __posh_debug /

    # Self destruct.
    unset -f __posh_init

    return $STATUS
}

# @description Loads the feature script if not already loaded.
#
# In order to make use of a feature it first needs to be loaded. It is safe to
# call this function multiple times for the same feature as it will not load it
# more than once. Once loaded, all of the functions in the feature should be
# available.
#
# @arg $1 The name of the feature.
#
# @exitcode 0 If the script was loaded.
# @exitcode 1 If the script failed to load.
__posh_load()
{
    local FEATURE_NAME="$1"

    # Inform of loading stage.
    __posh_debug + "loading feature: $FEATURE_NAME"

    # Make sure the script has not already been loaded.
    if echo "$__POSH_LOADED" | grep -q -F "$FEATURE_NAME"; then
        __posh_debug - "$FEATURE_NAME already loaded"
    else
        local FEATURE_SCRIPT="$__POSH_FEATURES/$FEATURE_NAME.sh"

        if . "$FEATURE_SCRIPT"; then
            __POSH_LOADED="$(printf "%s\n%s\n" "$FEATURE_NAME" "$__POSH_LOADED")"

            __posh_debug - "loaded: $FEATURE_NAME"
        else
            __posh_error - "could not be loaded: $FEATURE_NAME"

            return 1
        fi
    fi
}

# @description Prints to STDERR following an indentation level.
#
# The first argument will always be indentation control. Changes made to the
# indentation level only take effect with the next message that is logged. If
# no message is provided and only the control is given, the only the level is
# changed.
#
# - `-` &mdash; decreases the indentation level
# - `+` &mdash; increases the indentation level
# - `/` &mdash; resets the indentation level
# - `.` &mdash; does not change the indentation level
#
# @arg $1 The code to change the indent level.
# @arg $@ The arguments to print.
#
# @stderr The arguments that were provided.
__posh_log()
{
    local INDENT="$1"; shift

    # Only print if there is something available.
    if [ $# -gt 1 ]; then

        # Only print the leading whitespace.
        printf "%*s" "$__POSH_LOG_INDENT" "" >&2

        # Then print as usual.
        echo "$@" >&2
    fi

    # Indent future messages.
    case "$INDENT" in
        "-") __POSH_LOG_INDENT="$((__POSH_LOG_INDENT - 2))" ;;
        "+") __POSH_LOG_INDENT="$((__POSH_LOG_INDENT + 2))" ;;
        "/") __POSH_LOG_INDENT=0 ;;
        *) ;;
    esac
}

# @description Remembers that a feature has not been turned on.
#
# @arg $1 The name of the feature.
#
# @exitcode 0 If the feature was turned off.
# @exitcode 1 If the feature could not be turned off.
__posh_off()
{
    local FEATURE="$1"

    # Get the current list of features.
    local FEATURES=

    if ! FEATURES="$(__posh_get posh features)"; then
        return 1
    fi

    # Remove any existing entry from the list.
    FEATURES="$(echo "$FEATURES" | grep -v -F "|$FEATURE")"

    if ! __posh_set posh features "$FEATURES"; then
        __posh_error "$FEATURE: could not be turned off"

        return 1
    fi
}

# @description Remembers that a feature has been turned on.
#
# This function also controls the order in which features are loaded. The lower
# the number, the earlier the feature is loaded. While the number used for the
# load order is not constrained, it is recommended to keep it between zero and
# 999 (inclusive).
#
# @arg $1 The name of the feature.
# @arg $2 The load order (default: 50).
#
# @exitcode 0 If the feature was turned off.
# @exitcode 1 If the feature could not be turned off.
__posh_on()
{
    local FEATURE="$1"
    local PRIORITY="${2:-50}"

    # Get the current list of features.
    local FEATURES=

    if ! FEATURES="$(__posh_get posh features)"; then
        return 1
    fi

    # Remove any existing entry from the list.
    FEATURES="$(echo "$FEATURES" | grep -v -F "|$FEATURE")"

    # Add it to the list.
    FEATURES="$(printf '%03d|%s\n%s' "$PRIORITY" "$FEATURE" "$FEATURES" | sort)"

    if ! __posh_set posh features "$FEATURES"; then
        __posh_error "$FEATURE: could not be turned on"

        return 1
    fi
}

# @description Sets the value for a feature configuration setting.
#
# Normally, the value is written to a file that represents the configuration
# setting as provided. If the value is `-`, the value will actually be read
# from STDIN instead. If the value is not provided or an empty string, the
# file for the setting will be deleted if it exists.
#
# @arg $1 The name of the feature.
# @arg $2 The name of the setting.
# @arg $3 The value of the setting.
#
# @exitcode 0 If the value was set.
# @exitcode 1 If the value could not be set.
__posh_set()
{
    local FEATURE="$1"
    local SETTING="$2"
    local VALUE="$3"
    local DIR="$__POSH_CONFIG/$FEATURE"
    local FILE="$DIR/$SETTING"

    __posh_debug + "writing to: $FILE"

    if [ ! -d "$DIR" ] && ! mkdir -p "$DIR"; then
        __posh_error - "unable to create directory: $DIR"

        return 1
    fi

    # Use STDIN.
    if [ "$VALUE" = '-' ]; then
        __posh_debug . "writing value from STDIN"

        cat - > "$FILE"

    # Use the variable.
    elif [ "$VALUE" != '' ]; then
        __posh_debug . "writing value from string"

        echo "$VALUE" > "$FILE"

    # Delete the file.
    elif [ -f "$FILE" ]; then
        __posh_debug . "deleting the file"

        rm "$FILE"
    fi

    local STATUS=$?

    if [ $STATUS -ne 0 ]; then
        __posh_debug . "unable to set the value"
    fi

    __posh_debug -

    return $STATUS
}

posh()
{
    # Reset indent level.
    __posh_log /

    # Make sure we have a feature name.
    if [ "$1" = '' ]; then
        cat << HELP >&2
Usage: posh [FEATURE]
Manages shell customization features.

The features below are only accessible once they have been turned on. If you
would like to know more about a feature before turning it on, run the following
command (using the example feature in this case):

    posh example help

FEATURE

    The following features are available:

HELP

        find "$__POSH_FEATURES" -type f -name '*.sh' | sort | while read -r FEATURE; do
            FEATURE="$(basename "$FEATURE" .sh)"

            echo "        $FEATURE" >&2
        done

        echo >&2

        return 3
    fi

    local FEATURE="$1"; shift 1

    # Handle invocation of required command.
    local FUNCTION="__posh_feature_${FEATURE}"

    case "$1" in
        help|off|on)
            FUNCTION="${FUNCTION}_${1}"
            shift ;;
    esac

    # Invoke the function.
    __posh_debug + "invoking: $FUNCTION"

    if __posh_load "$FEATURE"; then
        if type "$FUNCTION" > /dev/null; then
            "$FUNCTION" "$@"

            local STATUS=$?

            __posh_debug -

            return $STATUS
        else
            __posh_error . "$FEATURE: invalid command"
            __posh_debug - "function does not exist: $FEATURE_FUNCTION"

            return 1
        fi
    fi

    return $?
}
