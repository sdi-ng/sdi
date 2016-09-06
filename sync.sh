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

eval $($PREFIX/configsdiparser.py $PREFIX/sdi.conf data)
if test $? != 0; then
    echo "ERROR: failed to load $PREFIX/sdi.conf file"
    exit 1
elif ! source $PREFIX/misc.sh; then
    echo "ERROR: failed to load $PREFIX/misc.sh file"
    exit 1
fi

# Check if make sence to run
test "$USEFASTDATADIR" = "yes" || exit 0

# Create the data dir acourding to the history format specified
DATADIR="$DATADIR-$(date +"$DATAHISTORYFORMAT")"
SDIMKDIR "$DATADIR" || exit 1

# Copy everything from memory to disk
for HOST in $(ls "$FASTDATADIR"); do
    SDIMKDIR "$DATADIR/$HOST" || exit 1
    for FILE in $(ls "$FASTDATADIR/$HOST"); do
        cat "$FASTDATADIR/$HOST/$FILE" >> "$DATADIR/$HOST/$FILE"
        rm -f "$FASTDATADIR/$HOST/$FILE" &> /dev/null
    done
done
