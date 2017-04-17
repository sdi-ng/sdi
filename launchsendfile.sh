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
fi


# merge ssh options
for OPT in "${SSHOPT[@]}"; do
    SSHOPTS="$SSHOPTS -o $OPT"
done


# the sendfile fifo
FILEFIFO="$FIFODIR/sendfile.fifo"
FINISHFIFO="$FIFODIR/sendfile_finish.fifo"
FILEBLOCK="$TMPDIR/sendfile.blocked"
FINISH="$TMPDIR/sdi.sendfile.finish"



# create the pids folder
mkdir -p $PIDDIRSYS
mkdir -p $FIFODIR

# create the fifo itself
rm -f $FILEFIFO 2> /dev/null
mkfifo $FILEFIFO

# create the finish fifo
rm -f $FINISHFIFO 2> /dev/null
mkfifo $FINISHFIFO

# create the blocked file
rm -f $FILEBLOCK 2> /dev/null
touch $FILEBLOCK

# create empty transfers file
rm -f $PIDDIRSYS/transfers.pid 2> /dev/null
touch $PIDDIRSYS/transfers.pid


# function to remove pids from transfers file
function transferend()
{
    (tail -f $FINISHFIFO & echo $! > $PIDDIRSYS/finishfifo.pid) |
    while read PID; do
        sed -i "/^$PID$/d" $PIDDIRSYS/transfers.pid
    done
}

# function to wait a scp ends
# adictionaly removes PID from pids file
function waittransferend()
{
    PID=$1
    DESTINATION=$2
    while test -d /proc/$PID; do
        sleep 0.5
    done
    echo $PID >> $FINISHFIFO

    echo 'echo $(date +%s) '$DESTINATION' >> '$FINISH'' >> $CMDDIR/$HOST
}

# this function will listen to the fifo and
# will launch the files transfers
function sendfiledeamon()
{

    (tail -f $FILEFIFO & echo $! > $PIDDIRSYS/tailfifo.pid) |
    while read HOST FILE DESTINATION; do
        # wait to send file
        RUNNING=$(cat $PIDDIRSYS/transfers.pid |wc -l)
        #while (( $RUNNING >= $SENDLIMIT )); do
        #    sleep 10
        #    RUNNING=$(cat $PIDDIRSYS/transfers.pid |wc -l)
        #done

        # check if host is blocked
        if grep -q "^$HOST$" $FILEBLOCK; then
            continue
        fi

        # run scp
        scp -q $SSHOPTS $FILE $HOST:$DESTINATION
        #printf "scp -q $SSHOPTS $FILE $HOST:$DESTINATION\n"
        &> /dev/null &

        # send a waittransferend look to this proccess
        PID=$!
        echo $PID >> $PIDDIRSYS/transfers.pid
        waittransferend $PID $DESTINATION &
    done
}

# run the deamon and finish watcher
transferend &
sendfiledeamon &
echo $! > $PIDDIRSYS/sendfiledaemon.pid



