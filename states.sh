#!/bin/bash

PREFIX=$(dirname $0)

if [ ! -e $PREFIX'/sdi.conf' ]; then
    echo "ERROR: The $PREFIX/sdi.conf  file does not exist or can not be accessed"
    exit 1
fi

source $PREFIX'/sdi.conf'

#test if config is loaded
if test $? != 0; then
    echo "ERROR: failed to load $PREFIX/sdi.conf file"
    exit 1
elif ! source $PREFIX/misc.sh; then
    echo "ERROR: failed to load $PREFIX/misc.sh file"
    exit 1
fi
# define STATEDIR
STATEDIR=$WWWDIR/states

# Save the states of the remote hosts.
function savestate()
{

    SELF=/proc/self/task/*
    basename $SELF > $PIDDIRSYS/statesdaemon.pid
    SELF=$(cat $PIDDIRSYS/statesdaemon.pid)

    # cahce and reload control
    CACHE=""
    RELOAD=false

    # on signal reload states functions
    trap "RELOAD=true" USR1

    while read HOST PSTATE PSTATETYPE; do
        test "$PSTATE" = "exit" && break

        test $RELOAD = true &&
            for FNC in $CACHE; do unset $FNC; done &&
            RELOAD=false && CACHE=""

        local WEBSTATEXML="$STATEDIR/$PSTATETYPE.xml"

        LOAD=0

        if ! test -f "$WEBSTATEXML"; then
            LOG "ERROR: file $WEBSTATEXML not found."
            continue
        fi

        LOGFILE="$DATADIR/$HOST/$HOST.log"
        STABLE="true"
        if ${PSTATETYPE}_getstateinfo 2> /dev/null; then
            # already loaded
            LOAD=1
        elif source $SHOOKS/$PSTATETYPE 2> /dev/null; then
            # check if state is enabled
            ENABLED=false
            for STT in $(ls $SHOOKS/*); do
                test $(basename $(realpath $STT)) = $PSTATETYPE &&
                ENABLED=true && break
            done

            test $ENABLED = false &&
            unset ${PSTATETYPE}_getstateinfo &&
            PRINT "ERROR: state $PSTATETYPE not enabled." "$LOGFILE" &&
            continue

            # now sourced
            LOAD=2
            CACHE="$CACHE ${PSTATETYPE}_getstateinfo"
        else
            PRINT "ERROR: state $PSTATETYPE not found." "$LOGFILE" &&
            continue
        fi

        # if just sourced, must run getstateinfo again
        test $LOAD = 2 && ${PSTATETYPE}_getstateinfo 2> /dev/null

        HOSTSTATEFILE="$STATEDIR/$PSTATETYPE/$HOST"

        if test -z "$PSTATE" || test "$PSTATE" == false; then
            # Remove $HOST entry from $WEBSTATEXML
            if test -f "$HOSTSTATEFILE"; then
                sed -ie "/hosts\/$HOST.xml\"/d" $WEBSTATEXML
                rm -f "$HOSTSTATEFILE"
            fi
        else
            # Add new host entry for this state in $WEBSTATXML
            tag="<\!--#include virtual=\"../hosts/$HOST.xml\"-->"
            if ! test -f "$HOSTSTATEFILE"; then
                sed -ie "/--NEW--/i\\\t$tag" $WEBSTATEXML
                touch "$HOSTSTATEFILE"
            fi
        fi
        unset SSUMARY
    done
    rm -f $PIDDIRSYS/statesdaemon.pid
}

function launchsavestate()
{
    (tail -f $SFIFO & echo $! > $PIDDIRSYS/savestatetail.pid) | savestate
    kill $(cat $PIDDIRSYS/savestatetail.pid) 2> /dev/null
    rm $PIDDIRSYS/savestatetail.pid
}

# Unset all sourced states functions
for STATE in $SHOOKS/*; do
    unset $(basename $STATE)_getstateinfo 2> /dev/null
done

# Create fifo that will be used to manage states
# and open function to read fifo
SSTATE="$PIDDIRSYS/statesdaemon.pid"
if (test -f $SSTATE && ! test -d /proc/$(cat $SSTATE)) ||
   (! test -f $SSTATE ); then
    rm -f $SFIFO
    mkfifo $SFIFO
    launchsavestate &
else
    printf "already running, "
fi
