#!/bin/bash

PREFIX=$(dirname $0)

eval $($PREFIX/configsdiparser.py all)
if test $? != 0; then
    echo "ERROR: failed to load $PREFIX/sdi.conf file"
    exit 1
elif ! source $PREFIX/misc.sh; then
    echo "ERROR: failed to load $PREFIX/misc.sh file"
    exit 1
fi

# define STATEDIR
STATEDIR=$WWWDIR/states

# Update the information about how many hosts are in the $1 state
function updatecnt() {
    WEBSTATECOUNT="$STATEDIR/$1-count.txt"
    WEBSTATESTATUS="$STATEDIR/$1-status.xml"
    OP=$2
    SUMMARYPHRASE=$3
    NHOSTS=$(cat $WEBSTATECOUNT)
    if test "$OP" = "sub" && test $NHOSTS -gt 0; then
        ((NHOSTS=NHOSTS-1))
    else
        ((NHOSTS=NHOSTS+1))
    fi
    printf "$NHOSTS\n" > $WEBSTATECOUNT
    printf "<$1>$SUMMARYPHRASE</$1>\n" $NHOSTS > $WEBSTATESTATUS
}

# Save the states of the remote hosts.
function savestate()
{
    while read HOST PSTATE PSTATETYPE; do

        if test "$PSTATE" = "exit"; then
            kill $(cat $PIDDIRSYS/fifo.pid)
            break
        fi

        local WEBSTATEXML="$STATEDIR/$PSTATETYPE.xml"

        if ! test -f "$WEBSTATEXML"; then
            LOG "ERROR: file $WEBSTATEXML not found."
            continue
        elif ! source $SHOOKS/$PSTATETYPE; then
            LOG "ERROR: fail loading $SHOOKS/$PSTATETYPE"
            continue
        elif ! getstateinfo; then
            LOG "ERROR: fail loading getstateinfo (in $SHOOKS/$PSTATETYPE)"
            continue
        else
            if test -z "$PSTATE" || test "$PSTATE" == false; then
                # Remove $HOST entry from $WEBSTATEXML
                if grep -q "hosts\/$HOST.xml\"" $WEBSTATEXML; then
                    sed -ie "/hosts\/$HOST.xml\"/d" $WEBSTATEXML
                    # Decreases in 1 the amount of hosts in this state
                    if ! test -z "$SSUMARY"; then
                        updatecnt $PSTATETYPE sub "$SSUMARY"
                    fi
                fi
            else
                # Add new host entry for this state in $WEBSTATXML
                tag="<\!--#include virtual=\"../hosts/$HOST.xml\"-->"
                if ! grep -q "$tag" $WEBSTATEXML; then
                    sed -ie "/--NEW--/i\\\t$tag" $WEBSTATEXML
                    # Increases in 1 the amount of hosts in this state
                    if ! test -z "$SSUMARY"; then
                        updatecnt $PSTATETYPE add "$SSUMARY"
                    fi
                fi
            fi
        fi
        unset SSUMARY
    done
}

function launchsavestate()
{
    (tail -f $SFIFO & echo $! > $PIDDIRSYS/savestatetail.pid) | savestate
    kill $(cat $PIDDIRSYS/savestatetail.pid) 2> /dev/null
    rm $PIDDIRSYS/savestatetail.pid
}

# Unset all sourced states functions
for STATE in $SHOOKS/*; do
    unset $(basename $STATE)_getstateinfo
done

# Create fifo that will be used to manage states
# and open function to read fifo
rm -f $SFIFO ; mkfifo $SFIFO
SSTATE="$PIDDIRSYS/savestate.pid"
( (test -f $SSTATE && ! test -d /proc/$(cat $SSTATE) ) ||
(! test -f $SSTATE )) && (launchsavestate & echo $! > $SSTATE)
