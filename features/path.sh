#!/bin/sh

# shellcheck disable=SC2155
# shellcheck disable=SC3043

# @description Displays a help message if the feature is enabled.
#
# @stderr The error message if the feature is not enabled.
# @stdout The help message if the feature is enabled.
#
# @exitcode 0 If the feature is enabled.
# @exitcode 1 If the feature is not enabled.
__posh_feature_path()
{
    # Make sure the feature is initialized.
    if [ "${__POSH_FEATURE_PATH_INIT:-0}" -eq 0 ]; then
        __posh_error . "path is not enabled"

        return 1
    fi

    # Get the managed paths.
    local MANAGED=

    if ! MANAGED="$(__posh_get path managed)"; then
        __posh_error . "path: unable to get managed paths"

        return 1
    fi

    # Process the command or display the help screen.
    local COMMAND="$1"

    case "$COMMAND" in
        add)

            # Make sure a path is provided.
            local NEW="$2"

            if [ -z "$NEW" ]; then
                __posh_error . "path: a path is required"

                return 1
            fi

            # Set a default priority if one is not given.
            local PRIORITY="${3:-50}"

            # Add the path to the list.
            MANAGED="$(printf "%03d|%s\n%s" "$PRIORITY" "$NEW" "$MANAGED" | sort -u)"

            # Save the changes.
            if ! __posh_set path managed "$MANAGED"; then
                __posh_error . "path: changes could not be saved"

                return 1
            fi

            # Apply the path changes.
            while read -r ITEM; do
                echo "$ITEM"
            done << EOF
$(echo "$MANAGED" | cut -d\| -f2)
EOF

            ;;

        current)
            echo "$PATH" | tr : "\n" | nl -s') ' -w 3 ;;

        list)
            echo "$MANAGED" | cut -d\| -f2 | nl -s') ' -w 3 ;;

        remove)

            # Make sure a path is provided.
            local OLD="$2"

            if [ -z "$OLD" ]; then
                __posh_error . "path: an unevaluated path is required"

                return 1
            fi

            # Exclude it from the list.
            if ! __posh_set path managed "$(echo "$MANAGED" | grep -vF "$2")"; then
                __posh_error . "path: changes could not be saved"

                return 1
            fi

            # Update PATH.
            local EVALUATED=

            if ! EVALUATED="$(__posh_feature_path_evaluated | tr '\n' :)"; then
                __posh_error . "path: could not update PATH"

                return 1
            fi

            PATH="$EVALUATED"

            ;;

        *)
            __posh_feature_path_help
            return 1;;
    esac
}

# @description Returns the managed and evaluated paths.
#
# This function will retrieve the current configured managed paths and then
# evaluate them. The resulting paths will be printed to STDOUT.
#
# @stderr If the paths could not be retrieved or evaluated.
# @stdout The evaluated paths.
#
# @exitcode 0 If the paths were retrieved and evaluated.
# @exitcode 1 If the paths could not be retrieved or evaluated.
__posh_feature_path_evaluated()
{
    # Get the managed paths.
    local MANAGED=

    if ! MANAGED="$(__posh_get path managed | cut -d\| -f2)"; then
        __posh_error . "path: unable to get managed paths"

        return 1
    fi

    # Evaluate the paths.
    if [ -n "$MANAGED" ]; then
        echo "$MANAGED" | while read -r UNEVALUATED; do
            if ! eval "echo \"$UNEVALUATED\""; then
                __posh_error . "path: could not evaluate: $UNEVALUATED"

                return 1
            fi
        done
    fi

    return $?
}

# @description Displays a help message for the feature.
__posh_feature_path_help()
{
    cat - << HELP >&2
Usage: posh feature path [COMMAND]
Manages control over the path feature.

COMMAND

    add      Adds a managed path.
    current  Shows a breakdown of the current PATH.
    help     Displays this help message.
    list     Displays all of the managed paths.
    off      Turns off this feature.
    on       Turns on this feature.
    remove   Removes a managed path.

Adding a Path

    When adding a path, an additional argument may be provided to specify
    the priority of the path among the other managed paths. The lower the
    number, the sooner the path is resolved. Useful when one path depends
    on another.

        posh path add '$HOME/.bin' 00
        posh path add '$HOME/.local/bin' 99

Removing a Path

    When removing a path, the provided path must match the unevaluated
    version that is being managed. If an evaluated path is used, it will
    not match and the path will not be removed.

        posh path remove '$HOME/.bin'
        posh path remove '$HOME/.local/bin'

HELP
}

# @description Initializes the feature in a new shell session.
#
# @exitcode 0 If the feature was initialized.
# @exitocde 1 If the feature could not be initialized.
__posh_feature_path_init()
{
    # Make sure this feature is not initialized more than once.
    if [ "${__POSH_FEATURE_PATH_INIT:-0}" -eq 1 ]; then
        __posh_debug "already initialized: path"

        return 0
    fi

    # Initialize the feature.
    __posh_debug + "initializing: path"

    # Set starting paths if nothing is configured.
    if [ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/posh/path/managed" ]; then
        local STARTING_PATHS="$(echo "$PATH" | tr : "\n" | nl -n rz -w 3 -s '|')"

        if ! __posh_set path managed "$STARTING_PATHS"; then
            __posh_error . "path: unable to set starting set of managed paths"

            return 1
        fi
    fi

    # Set the new PATH.
    local MANAGED=

    if ! MANAGED="$(__posh_feature_path_evaluated | tr '\n' :)"; then
        __posh_debug -

        return 1
    fi

    if [ -n "$MANAGED" ]; then
        PATH="$MANAGED"
    fi

    # Remember activation.
    export __POSH_FEATURE_PATH_INIT=1
}

# @description Manages the process of turning the feature off.
#
# @exitcode 0 If the feature was turned off.
# @exitcode 1 If the feature could not be turned off.
__posh_feature_path_off()
{
    # Make sure this feature is already on.
    if [ "${__POSH_FEATURE_PATH_INIT:-0}" -eq 0 ]; then
        __posh_debug . "already off: path"

        return 0
    fi

    # Clear the initialization flag.
    unset __POSH_FEATURE_PATH_INIT

    __posh_off path
}

# @description Manages the process of turning on the feature.
#
# @exitcode 0 If the feature was turned on.
# @exitcode 1 If the feature could not be turned on.
__posh_feature_path_on()
{
    # Make sure this feature is not turned on more than once.
    if [ "${__POSH_FEATURE_PATH_INIT:-0}" -eq 1 ]; then
        __posh_debug . "already on: path"

        return 0
    fi

    # Initialize the feature.
    if ! __posh_feature_path_init; then
        return 1
    fi

    __posh_on path
}

