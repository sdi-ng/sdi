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

SOURCE="$1"

if ! test -f $CMDGENERAL; then
    LOG "CRON: file not found: $CMDGENERAL"
elif test -d $HOOKS/$SOURCE.d; then
    cat $HOOKS/$SOURCE.d/* >> $CMDGENERAL
fi

