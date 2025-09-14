#!/bin/sh

# @description Provides users with a CLI to feature functionality.
#
# When a user executes `posh features example`, any arguments the command
# receives are passed to this catch all function. The only exception is when
# the first argument is `help`, `off`, or `on`. It is up to each feature to
# determine if this function should even be defined and what it should do.
#
# In this case, this function will provide a few extra commands to control
# the feature beyond simply turning it on and off or showing the help message.
#
# @arg $1 The command to process.
#
# @stdout If there is anything to tell the user.
#
# @exitcode 0 If the command was successful.
# @exitcode 1 If the command was not successful.
__posh_feature_example()
{
    # Only allow use after the feature has been initialized.
    #
    # While this may not be necessary for some features, in this feature it is.
    # The initialization process sets up the environment with information that
    # this function may depend on.
    if [ "${__POSH_EXAMPLE_INIT:-0}" -ne 1 ]; then
        __posh_error . "example is not enabled"

        return 1
    fi

    # If the user did not specify a command, set a default.
    if [ -z "$1" ]; then
        set -- help
    fi

    # Process the user's command.
    case "$1" in

        # Display the help screen.
        -h|--help|help)
            __posh_feature_example_help
            ;;

        # Reset the timestamp.
        -r|--reset|reset)
            # shellcheck disable=SC2155
            export EXAMPLE_WHEN="$(date)"

            echo "Session start time reset."
            ;;

        # Print the timestamp.
        print)
            echo "The session started on: $EXAMPLE_WHEN"
            ;;

        # Inform the user of an invalid command.
        *)
            __posh_error . "example: invalid command: $1"

            return 1
            ;;
    esac
}

# @description Displays a help message.
__posh_feature_example_help()
{
    cat - << HELP >&2
Usage: posh feature example [COMMAND]
An example of how a feature can be implemented.

COMMAND

    help   Displays this help message.
    off    Turns off this feature.
    on     Turns on this feature.
    print  Prints when the shell session started.
    reset  Resets the timestamp for session start.

HELP
}

# @description Modifies the curren shell session to implement the feature.
#
# The _init() function is always called by POSH when a new shell session is
# started and the feature has been turned on. Anything needed to ensure that
# the feature can be enabled would have been performed by the _on() function,
# such as installing dependencies, checking the environment, etc.
#
# @exitcode 0 If the feature was successfully initialized.
# @exitcode 1 If the feature could not be initialized.
__posh_feature_example_init()
{
    # Only initialize if this feature has not already.
    if [ "${__POSH_EXAMPLE_INIT:-0}" -eq 1 ]; then
        return 0
    else
        export __POSH_EXAMPLE_INIT=1
    fi

    # shellcheck disable=SC2155
    export EXAMPLE_WHEN="$(date)"

    __posh_debug . "example is initialized"
}

# @description Manages the process of turning the feature off.
#
# The purpose of the _off() function is to remind POSH that the feature has
# been turned off and to clean up after the feature. The clean up process
# should effectively unload the feature from the shell environment and also
# clean up anything left on the file system.
__posh_feature_example_off()
{
    # Tell POSH not to remember this feature is on.
    #
    # If we do not do this, the next time the user creates a new shell session
    # the _init() function for this feature will be called again. If we did the
    # clean up process without doing this step, it could result in a broken
    # shell session.
    __posh_off example

    # Delete this feature's now unused environment variable.
    unset EXAMPLE_WHEN
}

# @description Manages the process of turning the feature on.
#
# The purpose of the _on() function is to check if the feature is a) already
# enabled and b) the environment supports the feature. Once all of the needed
# checks are performed, the function will finally call `__posh_on $FEATURE` to
# tell POSH to remember the feature is on. It will be on the _on() function to
# determine if the feature's _init() function should be called.
#
# @exitcode 0 If the feature was turned on (or is already on).
# @exitcode 1 If the feature could not be turned on.
#
# @see __posh_feature_example_init()
__posh_feature_example_on()
{
    # Make sure this feature has not already been turned on.
    #
    # There may be cases where the feature may allow the user to turn the
    # same feature on more than once. For example, turning the feature on
    # could reset any saved state. In this simple case, I just want to
    # demonstrate how we could prevent the user from turning the feature
    # on when it is already on.
    if [ "${__POSH_EXAMPLE_INIT:-0}" -eq 0 ]; then

        # Tell POSH to remember this feature is on.
        if __posh_on example; then

            # Initialize the feature immediately.
            #
            # We could put off initializing the feature until the user starts
            # a new shell session, but that would be inconvenient in this case.
            # By initializing the moment the feature is turned on, the user can
            # start using it in their current shell session.
            __posh_feature_example_init
        fi

    # Log if another attempt to turn it on was caught.
    #
    # Under normal use, this condition should never be encountered. However,
    # if a new feature is under active development, the user directly edited
    # a POSH configuratoin file, or POSH is buggy, this little note could help
    # bring awareness and debug the problem.
    else
        __posh_debug . example is already enabled
    fi
}