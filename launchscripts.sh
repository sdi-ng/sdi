#############################################################
# SDI is an open source project.
# Licensed under the GNU General Public License v2.
#
# File Description:
#
#
#############################################################

#!/bin/bash

PREFIX=$(dirname $0)

if ! source $PREFIX/misc.sh; then
    echo "SDI(cron): failed to load $PREFIX/misc.sh"
    exit 1
fi

eval $($PREFIX/configsdiparser.py $PREFIX/sdi.conf general)
if test $? != 0; then
    LOG "CRON: failed to load sdi configuration file: $PREFIX/sdi.conf"
    exit 1
fi

SOURCE="$1"

if ! test -f $CMDGENERAL; then
    LOG "CRON: file not found: $CMDGENERAL"
elif test -d $HOOKS/$SOURCE.d; then
    cat $HOOKS/$SOURCE.d/* >> $CMDGENERAL
fi

