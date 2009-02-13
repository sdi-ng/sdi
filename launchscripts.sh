#!/bin/bash

PREFIX=$(dirname $0)

if ! source $PREFIX/misc.sh; then
    echo "SDI(cron): failed to load $PREFIX/misc.sh"
    exit 1
fi

eval $($PREFIX/configsdiparser.py all)
if test $? != 0; then
    LOG "CRON: failed to load sdi configuration file: $PREFIX/sdi.conf"
    exit 1
fi

SOURCE="$1"

if ! test -f $CMDDIR/general; then
    LOG "CRON: file not found: $CMDDIR/general"
elif test -d $HOOKS/$SOURCE.d; then
    cat $HOOKS/$SOURCE.d/* >> $CMDDIR/general
fi

