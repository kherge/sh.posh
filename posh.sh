#!/bin/sh

# shellcheck disable=SC1090
# shellcheck disable=SC3043

# @description Provides an interface to control shell customization features.
#
# In order to use this function, the POSH_DIR environment variable must be
# defined using the path to the directory that contains this script. The
# command will then be available as `posh`. To enable debugging mode, define
# the POSH_DEBUG environment variable with a value of `1`.
#
# @arg $@ Used to process internal commands or forwarded to features.
#
# @exitcode 0 If anything was successful.
# @exitcode 1 If anything failed.
posh()
{
    # Make sure we know where we are.
    if [ -z "$POSH_DIR" ]; then
        echo "POSH_DIR: must be defined" >&2

        return 1
    elif [ ! -f "$POSH_DIR/posh.sh" ]; then
        echo "POSH_DIR: must be POSH directory" >&2

        return 1
    fi

    # Define shared context.
    local FEATURES_DIR="$POSH_DIR/features"

    # Using internal commands?
    if [ "$1" = '--' ]; then
        local COMMAND="$2"; shift 2
        local CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/posh"

        case "$COMMAND" in
            debug)
                if [ "${POSH_DEBUG:-0}" -eq 1 ]; then
                    echo '[DEBUG] posh:' "$@" >&2
                fi ;;

            error)
                shift

                if [ "${POSH_DEBUG:-0}" -eq 1 ]; then
                    echo '[ERROR] posh:' "$@" >&2
                else
                    echo 'posh:' "$@" >&2
                fi ;;

            get)
                # Compose the path to the configuration file.
                IFS=/
                local FILE="$CONFIG_DIR/$*"
                IFS=

                # Only try to get the value if the file exists.
                if [ -f "$FILE" ]; then
                    # shellcheck disable=SC2145
                    posh -- debug "get($@) reading from: $FILE"

                    cat "$FILE"
                else
                    # shellcheck disable=SC2145
                    posh -- debug "get($@) no such file: $FILE"
                fi

                return $? ;;

            init)

                # Are we initializing the shell session?
                if [ "$1" = '' ]; then
                    local FEATURES="$CONFIG_DIR/posh/features"

                    if [ -f "$FEATURES" ]; then
                        while read -r FEATURE; do
                            FEATURE="$(echo "$FEATURE" | cut -d\| -f2)"

                            posh -- init "$FEATURE"
                        done < "$FEATURES"
                    fi

                # Are we initializing a specific plugin?
                else
                    local FEATURE="$1"; shift
                    local FEATURE_FUNCTION="__posh_feature_${FEATURE}"
                    local FEATURE_SCRIPT="$FEATURES_DIR/$FEATURE.sh"

                    if [ -f "$FEATURE_SCRIPT" ]; then
                        posh -- debug "loading $FEATURE"

                        if . "$FEATURE_SCRIPT"; then
                            if type "${FEATURE_FUNCTION}_help" > /dev/null && \
                               type "${FEATURE_FUNCTION}_init" > /dev/null && \
                               type "${FEATURE_FUNCTION}_off"  > /dev/null && \
                               type "${FEATURE_FUNCTION}_on"   > /dev/null; then
                                if "${FEATURE_FUNCTION}_init"; then
                                    posh -- debug "initialized $FEATURE"
                                fi
                            else
                                posh -- error "$FEATURE: not a valid feature"
                            fi
                        else
                            posh -- error "$FEATURE: could not be loaded"
                        fi
                    else
                        posh -- error "$FEATURE: no such feature"

                        return 1
                    fi
                fi ;;

            off)
                local FEATURE="$1"

                # Get the current list of features.
                local FEATURES=

                if ! FEATURES="$(posh -- get posh features)"; then
                    return 1
                fi

                # Remove any existing entry from the list.
                FEATURES="$(echo "$FEATURES" | grep -v -F "|$FEATURE")"

                if ! posh -- set posh features "$FEATURES"; then
                    posh -- error "$FEATURE: could not be turned off"

                    return 1
                fi ;;

            on)
                local FEATURE="$1"
                local PRIORITY="${2:-50}"

                # Get the current list of features.
                local FEATURES=

                if ! FEATURES="$(posh -- get posh features)"; then
                    return 1
                fi

                # Remove any existing entry from the list.
                FEATURES="$(echo "$FEATURES" | grep -v -F "|$FEATURE")"

                # Add it to the list.
                FEATURES="$(printf '%03d|%s\n%s' "$PRIORITY" "$FEATURE" "$FEATURES" | sort)"

                if ! posh -- set posh features "$FEATURES"; then
                    posh -- error "$FEATURE: could not be turned on"

                    return 1
                fi ;;

            set)
                # Compose the path to the configuration file.
                local DIR="$CONFIG_DIR/$1"
                local FILE="$DIR/$2"

                # Create the directory if it does not exist.
                if [ ! -d "$DIR" ]; then
                    if ! mkdir -p "$DIR"; then
                        return 1
                    fi
                fi

                # Write STDIN to the file.
                if [ "$3" = '-' ]; then
                    posh -- debug "set($1 $2): writing from STDIN to: $FILE"

                    cat - > "$FILE"

                # Write the value to the file.
                elif [ "$3" != "" ]; then
                    posh -- debug "set($1 $2): writing from string to: $FILE"

                    echo "$3" > "$FILE"

                # Delete the file if it exists.
                elif [ -f "$FILE" ]; then
                    posh -- debug "set($1 $2): delete file: $FILE"

                    rm "$FILE"
                fi

                return $?
        esac

    # Controlling features?
    else
        :
    fi
}