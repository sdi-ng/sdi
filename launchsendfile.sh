#!/bin/bash

PREFIX=$(dirname $0)

source $PREFIX/sdi.conf

# Customizable variables, please refer to sdi.conf to change these values
: ${SENDLIMIT:=1}
: ${TMPDIR:=/tmp/sdi}
: ${PIDDIR:=$TMPDIR/pids}
: ${PIDDIRSYS:=$PIDDIR/system}
: ${FIFODIR:=$TMPDIR/fifos}

# the sendfile fifo
FILEFIFO="$FIFODIR/sendfile.fifo"
FILEBLOCK="$TMPDIR/sendfile.blocked"
FINISH="/tmp/.sdi.sendfile.finish"

# create the pids folder
mkdir -p $PIDDIRSYS
mkdir -p $FIFODIR

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
    sed -i "/^$PID$/d" $PIDDIRSYS/transfers.pid
    echo 'echo $(date +%s) '$DESTINATION' >> '$FINISH'' >> $CMDDIR/$HOST
}


# this function will listen to the fifo and
# will launch the files transfers
function sendfiledeamon()
{
    (tail -f $FILEFIFO & echo $! > $PIDDIRSYS/tailfifo.pid) |
    while read HOST FILE DESTINATION LIMIT; do
        # wait to send file
        RUNNING=$(cat $PIDDIRSYS/transfers.pid |wc -l)
        while (( $RUNNING >= $SENDLIMIT )); do
            sleep 10
            RUNNING=$(cat $PIDDIRSYS/transfers.pid |wc -l)
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
        echo $PID >> $PIDDIRSYS/transfers.pid
        waittransferend $PID $DESTINATION &
    done
}

# run the deamon
sendfiledeamon &
echo $! > $PIDDIRSYS/deamon.pid
