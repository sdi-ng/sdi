#!/bin/bash

PREFIX=$(dirname $0)

if ! source $PREFIX/sdi.conf; then
    echo "ERROR: failed to load $PREFIX/sdi.conf file"
    exit 1
elif ! source $PREFIX/misc.sh; then
    echo "ERROR: failed to load $PREFIX/misc.sh file"
    exit 1
fi

# check if realpath command is available
test -x "$(which realpath)" ||
    { printf "FATAL: \"realpath\" must be installed\n" && exit 1; }

# Customizable variables, please refer to sdi.conf to change these values
: ${DATADIR:=$PREFIX/data}
: ${PIDDIR:=$TMPDIR/pids}
: ${PIDDIRSYS:=$PIDDIR/system}
: ${SHOOKS:=$PREFIX/states-enabled}
: ${CLASSESDIR:=$PREFIX/CLASSES}
: ${CLASSNAME:=Class}
: ${WWWDIR:=$PREFIX/www}
: ${SDIWEB:=$PREFIX/sdiweb}
: ${HOSTCOLUMNNAME:="Host"}
: ${DEFAULTCOLUMNS:="Uptime"}
: ${FIFODIR:=$TMPDIR/fifos}
: ${SFIFO:=$FIFODIR/states.fifo}

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
    (tail -f -n0 $SFIFO & echo $! > $PIDDIRSYS/fifo.pid) |
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

# Create necessary folders
SDIMKDIR $TMPDIR || exit 1
SDIMKDIR $PIDDIR || exit 1
SDIMKDIR $PIDDIRSYS || exit 1
SDIMKDIR $WWWDIR/hosts || exit 1
SDIMKDIR $STATEDIR || exit 1
SDIMKDIR $FIFODIR || exit 1
SDIMKDIR $CLASSESDIR || exit 1

# Check if theres some class defined
CLASSES=$(ls $CLASSESDIR)
CLASSESNUM=$(ls $CLASSESDIR |wc -l)
if test $CLASSESNUM -eq 0; then
    printf "ERROR: no class set. At least one class of hosts must be defined
    in $CLASSESDIR directory.\n"
    exit 1
fi

# Generate web pages
if test $WEBMODE = true; then
    # Real create the pages
    source $SDIWEB/generatewebfiles.sh

    # Create fifo that will be used to manage states
    # and open function to read fifo
    # Only usefull if WEBMODE is activated
    rm -f $SFIFO ; mkfifo $SFIFO
    SSTATE="$PIDDIRSYS/savestate.pid"
    ( (test -f $SSTATE && ! test -d /proc/$(cat $SSTATE) ) ||
    (! test -f $SSTATE )) && (savestate & echo $! > $SSTATE)
else
    printf "$0: warning: web mode is disabled.\n"
fi

# Start sendfile deamon
DAEMON="$PIDDIRSYS/deamon.pid"
printf "Launching sendfile deamon... "
( (test -f $DAEMON && ! test -d /proc/$(cat $DAEMON) ) ||
(! test -f $DAEMON )) && bash $PREFIX/launchsendfile.sh
printf "done\n"

# Start launching the tunnels
COUNT=0
for CLASS in $CLASSES; do
    ((COUNT++))
    printf "Starting $CLASS ($COUNT/$CLASSESNUM)...\n"
    sleep 0.5

    HOSTS=$(awk '{print $1}' $CLASSESDIR/$CLASS)

    # Launch the tunnels
    DAEMON=true bash launchsditunnel.sh "$HOSTS"
    sleep 0.5
done

printf "All done.\n"
