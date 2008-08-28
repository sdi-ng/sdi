#!/bin/bash
PREFIX=$(dirname $0)

source $PREFIX/sdi.conf

: ${LOG:=$PREFIX/sdi.log}

# Function to update the sdi log.
# The log message contains the seconds since
# 1970 and the contents of $1 parameter
function LOG()
{
    echo "$(date +%s) $1" >> $LOG
}

