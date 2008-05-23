#!/bin/bash

PREFIX=.

source $PREFIX/sdi.conf

#these are minimal configuracao needed, user may overwrite any of them by
#defining at sdi.conf
: ${TIMEOUT=240}
: ${SSHOPT[0]="PreferredAuthentications=publickey"}
: ${SSHOPT[1]="StrictHostKeyChecking=no"}
: ${SSHOPT[2]="ConnectTimeOut=$TIMEOUT"}
: ${SSHOPT[3]="TCPKeepAlive=yes"}
: ${SSHOPT[4]="ServerAliveCountMax=3"}
: ${SSHOPT[5]="ServerAliveInterval=100"}

: ${CMDDIR:=$PREFIX/cmds}
: ${OUTDIR:=$PREFIX/coleta}
: ${TMPDIR:=/tmp/SDI}

: ${LAUNCHDELAY:=0.1}
: ${DAEMON:=false}

for OPT in "${SSHOPT[@]}"; do
    SSHOPTS="$SSHOPTS -o $OPT"
done


function SDISCRIPTS()
{
     for SDI in $PREFIX/scripts/SDI/*; do
         echo "echo '$(cat $SDI)' > /root/SDI/SDI/$(basename $SDI)"
     done;
}
function SDITUNNEL()
{
    TMP=$(mktemp -p $TMPDIR)
    CMDFILE=$CMDDIR/$1
    while ! test -f $TMPDIR/SDIFINISH ;do
        rm -f $CMDFILE
        touch $CMDFILE
        (tail -f $CMDFILE & jobs -p > $TMP) |
        (ssh $SSHOPTS $1 "rm -rf /root/SDI; mkdir -p /root/SDI/SDI;
             $(SDISCRIPTS);
             $(cat scripts/client.sh);
             " >> $OUTDIR/$1 2>&1
        kill $(cat $TMP) &>/dev/null )
        sleep $(bc <<< "($RANDOM%600)+120")
    done
    rm $TMP
}

if test $# -eq 0  ; then
    echo "Usage:"
    echo "  $0 host1 [host2 [host3 [host... ]]]"
    exit 1
fi

#Create temporary directory
mkdir -p $TMPDIR

#Start launching SDI tunnels
for HOST in $*; do
    echo $HOST
    SDITUNNEL $HOST &
    sleep $LAUNCHDELAY
done

if test $DAEMON = true; then
    exit 0
else
    printf "Waiting SDI Tunnels to finish"
    wait $(jobs -p)
    printf ".\n"
    exit 0
fi
