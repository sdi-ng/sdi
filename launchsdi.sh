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

# check if realpath command is available
test -x "$(which realpath)" ||
    { printf "FATAL: \"realpath\" must be installed\n" && exit 1; }

# define STATEDIR
STATEDIR=$WWWDIR/states

# Create necessary folders
SDIMKDIR $TMPDIR || exit 1
SDIMKDIR $PIDDIR || exit 1
SDIMKDIR $PIDDIRSYS || exit 1
SDIMKDIR $WWWDIR/hosts || exit 1
SDIMKDIR $STATEDIR || exit 1
SDIMKDIR $FIFODIR || exit 1
SDIMKDIR $CLASSESDIR || exit 1

# Start runing tunnels for hosts
CLASSES=$(ls $CLASSESDIR)
CLASSESNUM=$(ls $CLASSESDIR |wc -l)
if test $CLASSESNUM -eq 0; then
    printf "ERROR: no class set. At least one class of hosts must be defined
    in $CLASSESDIR directory.\n"
    exit 1
fi

# Check if web mode is enabled
if test $WEBMODE = true; then
    source $SDIWEB/generatewebfiles.sh

    # Start states daemon
    printf "Launching states daemon... "
    bash $PREFIX/states.sh
    printf "done\n"
else
    printf "$0: warning: web mode is disabled.\n"
fi

# Open socketdaemon
$PREFIX/socketdaemon.py & disown

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
