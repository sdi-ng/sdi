#!/bin/bash

PREFIX=$(dirname $0)

source $PREFIX/sdi.conf

# Customizable variables, please refer to sdi.conf to change these values
: ${SENDLIMIT:=1}
: ${TMPDIR:=/tmp/sdi}
: ${PIDDIR:=$TMPDIR/pids}

# the sendfile fifo
FILEFIFO="$TMPDIR/sendfilefifo"
FILEBLOCK="$TMPDIR/sendfile.blocked"
FINISH="/tmp/.sdi.sendfile.finish"

# create the pids folder
mkdir -p $PIDDIR/sendfile

# create the fifo itself
rm -f $FILEFIFO 2> /dev/null
mkfifo $FILEFIFO

# create the blocked file
rm -f $FILEBLOCK 2> /dev/null
touch $FILEBLOCK

# function to wait a scp ends
# adictionaly removes PID from pids file
function waittransferend()
{
    PID=$1
    DESTINATION=$2
    while test -d /proc/$PID; do
        sleep 0.5
    done
    sed -i "/^$PID$/d" $PIDDIR/sendfile/transfers.pid
    echo 'echo $(date +%s) '$DESTINATION' >> '$FINISH'' >> $CMDDIR/$HOST
}


# this function will listen to the fifo and
# will launch the files transfers
function sendfiledeamon()
{
    (tail -f $FILEFIFO & echo $! > $PIDDIR/sendfile/tailfifo.pid) |
    while read HOST FILE DESTINATION LIMIT; do
        # wait to send file
        RUNNING=$(cat $PIDDIR/sendfile/transfers.pid |wc -l)
        while (( $RUNNING >= $SENDLIMIT )); do
            sleep 10
            RUNNING=$(cat $PIDDIR/sendfile/transfers.pid |wc -l)
        done

        # check if host is blocked
        if grep -q "^$HOST$" $FILEBLOCK; then
            continue
        fi

        # check limit
        if (( $LIMIT == 0 )); then
            LIMIT=""
        else
            LIMIT="-l$LIMIT"
        fi

        # run scp
        scp $LIMIT $FILE $SDIUSER@$HOST:$DESTINATION &

        # send a waittransferend look to this proccess
        PID=$!
        echo $PID >> $PIDDIR/sendfile/transfers.pid
        waittransferend $PID $DESTINATION &
    done
}

# run the deamon
sendfiledeamon &
echo $! > $PIDDIR/sendfile/deamon.pid
