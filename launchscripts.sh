#!/bin/bash

sdiroot=.

if ! source $sdiroot/misc.sh; then
    echo "SDI(cron): failed to load $sdiroot/misc.sh"
    exit 1
fi

if ! source $sdiroot/sdi.conf; then
    LOG "CRON: failed to load sdi configuration file: $sdiroot/sdi.conf"
    exit 1
fi

: ${CMDDIR:=$sdiroot/cmds}
: ${HOOKS:=$sdiroot/commands-enabled}

SOURCE="$1"

if ! test -f $CMDDIR/general; then
    LOG "CRON: file not found: $CMDDIR/general"
elif test -d $HOOKS/$SOURCE.d; then
    cat $HOOKS/$SOURCE.d/* >> $CMDDIR/general
fi

