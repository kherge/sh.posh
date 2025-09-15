#!/bin/sh

# shellcheck disable=SC3043

# @description Displays the help message if the plugin is enabled.
__posh_feature_bookmark()
{
    if type b > /dev/null; then
        __posh_feature_bookmark_help
    else
        __posh_error . "bookmark is not enabled"

        return 1
    fi
}

# @description Displays a help message for the feature.
__posh_feature_bookmark_help()
{
    cat - << HELP >&2
Usage: posh bookmark [COMMAND]
Manages control over the bookmark feature.

COMMAND

    help   Displays this help message.
    off    Turns off this feature.
    on     Turns on this feature.

Setting a Bookmark

        b ALIAS PATH

    The PATH can be a normal file or directory path, or it may be an
    unevaluated representation of a path (e.g. '\$HOME/path/to/thing'). When
    the bookmark is used, the path will be evaluated before the current working
    directory is changed to it. If the alias is already in use, the path for it
    will be replaced with the new path provided.

    The following are equivalent:

        b workspace /home/user/Workspace
        b workspace '\$HOME/Workspace'
        b workspace '~/Workspace'

Unsetting a Bookmark

        b ALIAS -

    Similar to setting an ALIAS, except the path must be a dash (\`-\`). The
    next time the bookmark is used, an error will be shown as the bookmark
    will no longer exist.

Using a Bookmark

        b ALIAS

    The alias can be any path that was set previously. Whe the command is run,
    the path for the alias is first evaluated and the result is the path that
    the shell will change directory to.

        b workspace

    is equivalent to

        cd /home/user/Workspace

Listing All Bookmarks

        b

    When called without any arguments, all of the available bookmarks are
    listed. The paths shown will be their unevaluated versions, the same
    values that were initially provided.

HELP
}

# @description Prints a list of available bookmarks.
#
# @stdout The available bookmarks.
#
# @exitcode 1 If the bookmarks could not be read.
__posh_feature_bookmark_list()
{
    # Get the available bookmarks.
    local BOOKMARKS=

    if ! BOOKMARKS="$(__posh_get bookmark paths)"; then
        __posh_error "bookmark: could not retrieve bookmarks"

        return 1
    fi

    # Display them to the user.
    printf "%-10s   %s\n" Alias Path
    printf "%-10s   %s\n" '-----' '----'

    # shellcheck disable=SC2155
    echo "$BOOKMARKS" | while read -r BOOKMARK; do
        local ALIAS="$(echo "$BOOKMARK" | cut -d\| -f1)"
        local DESTINATION="$(echo "$BOOKMARK" | cut -d\| -f2)"

        printf "%-10s   %s\n" "$ALIAS" "$DESTINATION"
    done
}

# @description Initializes the feature in a new shell session.
#
# @exitcode 0 If the feature was initialized.
# @exitocde 1 If the feature could not be initialized.
__posh_feature_bookmark_init()
{
    # Make sure this feature is not initialized more than once.
    if [ "${__POSH_FEATURE_BOOKMARK_INIT:-0}" -eq 1 ]; then
        __posh_debug "already initialized: bookmark"

        return 0
    fi

    # Initialize the feature.
    __posh_debug "initializing: bookmark"

    # @description Changes directory to the specified bookmark.
    #
    # This function accepts the alias of the bookmark as the first argument.
    # If the bookmark exists, then the current working directory will be set
    # to the bookmarked path.
    #
    # @arg $1 The bookmark alias.
    #
    # @stderr If the bookmark does not exist.
    #
    # @exitcode 0 If the current working directory was changed.
    # @exitcode 1 If the directory could not be changed.
    #
    # shellcheck disable=SC2329
    b()
    {
        # Get all of the available bookmarks.
        local BOOKMARK=
        local BOOKMARKS=

        if ! BOOKMARKS="$(__posh_get bookmark paths | awk 'NF')"; then
            __posh_error . "bookmark: unable to get bookmarks"

            return 1
        fi

        # Was an alias not provided?
        if [ "$1" = '' ]; then

            # Shortcut if there are no bookmarks.
            if [ -z "$BOOKMARKS" ]; then
                echo "posh: bookmark: no bookmarks available"

                return 0
            fi

            # Find the length of the longest alias.
            local LONGEST=5

            # shellcheck disable=SC2155
            while read -r BOOKMARK; do
                local LENGTH="$(echo "$BOOKMARK" | cut -d\| -f1)"
                      LENGTH="$(expr "$LENGTH" : '.*')"

                if [ "$LENGTH" -gt "$LONGEST" ]; then
                    LONGEST=$LENGTH
                fi
            done << EOF
$BOOKMARKS
EOF

            # Print the available bookmarks.
            # shellcheck disable=SC2155
            echo "$BOOKMARKS" | while read -r BOOKMARK; do
                local ALIAS="$(echo "$BOOKMARK" | cut -d\| -f1)"
                local LOCATION="$(echo "$BOOKMARK" | cut -d\| -f2)"

                printf "%-${LONGEST}s    %s\n" "$ALIAS" "$LOCATION"
            done
            echo

        # Are we using an alias?
        elif [ "$2" = '' ]; then

            # Make sure the book mark exists.
            BOOKMARK="$(echo "$BOOKMARKS" | grep "^$1|")"

            if [ -z "$BOOKMARK" ]; then
                __posh_error . "bookmark: no such alias"

                return 1
            fi

            # Change directory.
            local LOCATION=

            if LOCATION="$(eval "echo \"$(echo "$BOOKMARK" | cut -d\| -f2)\"")"; then
                # shellcheck disable=SC2164
                cd "$LOCATION"
            fi

            return $?

        # Are we changing an alias?
        else

            # Remove it if defined.
            BOOKMARKS="$(printf "%s" "$BOOKMARKS" | grep -v "^$1|")"

            # Are we setting an alias?
            if [ "$2" != '-' ]; then
                BOOKMARKS="$(printf "%s|%s\n%s" "$1" "$2" "$BOOKMARKS" | sort)"
            fi

            # Save the changes.
            if ! __posh_set bookmark paths "$BOOKMARKS"; then
                __posh_error "bookmark: unable to save bookmark"

                return 1
            fi
        fi
    }

    # Remember activation.
    export __POSH_FEATURE_BOOKMARK_INIT=1
}

# @description Manages the process of turning the feature off.
#
# @exitcode 0 If the feature was turned off.
# @exitcode 1 If the feature could not be turned off.
__posh_feature_bookmark_off()
{
    # Make sure this feature is already on.
    if [ "${__POSH_FEATURE_BOOKMARK_INIT:-0}" -eq 0 ]; then
        __posh_debug . "already off: bookmark"

        return 0
    fi

    # Clear the initialization flag.
    unset __POSH_FEATURE_BOOKMARK_INIT
    unset -f b

    __posh_off bookmark
}

# @description Manages the process of turning on the feature.
#
# @exitcode 0 If the feature was turned on.
# @exitcode 1 If the feature could not be turned on.
__posh_feature_bookmark_on()
{
    # Make sure this feature is not turned on more than once.
    if [ "${__POSH_FEATURE_BOOKMARK_INIT:-0}" -eq 1 ]; then
        __posh_debug . "already on: bookmark"

        return 0
    fi

    # Initialize the feature.
    if ! __posh_feature_bookmark_init; then
        return 1
    fi

    __posh_on bookmark
}
