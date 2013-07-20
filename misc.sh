#!/bin/bash
PREFIX=$(dirname $0)

eval $($PREFIX/configsdiparser.py $PREFIX/sdi.conf shell general)
if test $? != 0; then
    echo "ERROR: failed to load $PREFIX/sdi.conf file"
    exit 1
fi

# Function to update the sdi log.
# The log message contains the seconds since
# 1970 and the contents of $1 parameter
LOG()
{
    echo "$(date +%s) $1" >> $LOG
}

# Write $1 (string) into $2 (file) with the seconds since 1970
PRINT()
{
    echo "$(date +%s) $1" >> $2
}

# Create a directory and ensure that it is accessible, or exit SDI
SDIMKDIR()
{
    dir=$1
    if ! (mkdir -p $dir &&
          test -O $dir &&
          test -r $dir &&
          test -w $dir &&
          test -x $dir); then
        printf "Unable to create directory \"$dir\".\n"
        printf "Check if you are the owner of \"$dir\" and have r/w/x "
        printf "permissions to access it and then try to run SDI again.\n"
        return 1
    else
        return 0
    fi
}

# $1 - PID of process that is listening the fifo
# $2 - Name of fifo file. closefifo() will look for this file in $FIFODIR
closefifo()
{
    PIDFIFO=$1
    FIFO=$2
    test -d /proc/$PIDFIFO && echo "exit exit exit" >> $FIFODIR/$FIFO &&
    waitend $PIDFIFO
    rm -f $FIFODIR/$FIFO
}

