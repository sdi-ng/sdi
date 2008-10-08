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

# Write $1 (string) into $2 (file) with the seconds since 1970
function PRINT()
{
    echo "$(date +%s) $1" >> $2
}

# Create a directory and ensure that it is accessible, or exit SDI
function SDIMKDIR()
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
        exit 1
    fi
}
