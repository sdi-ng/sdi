#!/bin/bash

PREFIX=.

source $PREFIX/sdi.conf

# These are minimal configuration needed, user may overwrite any of them by
# defining at sdi.conf
: ${TIMEOUT:=240}
: ${SSHOPT[0]:="PreferredAuthentications=publickey"}
: ${SSHOPT[1]:="StrictHostKeyChecking=no"}
: ${SSHOPT[2]:="ConnectTimeOut=$TIMEOUT"}
: ${SSHOPT[3]:="TCPKeepAlive=yes"}
: ${SSHOPT[4]:="ServerAliveCountMax=3"}
: ${SSHOPT[5]:="ServerAliveInterval=100"}

: ${CMDDIR:=$PREFIX/cmds}
: ${DATADIR:=$PREFIX/data}
: ${TMPDIR:=/tmp/SDI}
: ${PIDDIR:=$TMPDIR/pids}
: ${HOOKS:=$PREFIX/commands-enabled}
: ${CMDGENERAL:=$CMDDIR/general}
: ${SDIUSER:=$USER}

#Customizable variables, please refer to wwwsdi.conf to change these values
: ${WWWDIR:=$PREFIX/www}
: ${WEBMODE:=true}
: ${SDIWEB:=$PREFIX/sdiweb}

: ${LAUNCHDELAY:=0.1}
: ${DAEMON:=false}

for OPT in "${SSHOPT[@]}"; do
    SSHOPTS="$SSHOPTS -o $OPT"
done

function usage()
{
    echo "Usage:"
    echo "  $0 [options] host1 [host2 [host3 [host... ]]]"
    echo "Options:"
    echo "  --kill=HOST    Close the SDI tunnel for HOST"
    echo "  --killall      Close all SDI tunnels and stop SDI application"
}

function getvars()
{
    # Format of vars: nameofvar:obligation:default:webtag
    # Separator is ','
    local VARS="PVALUE:true::value
    PSTATUS:::class
    PSORTCUSTOM:::sorttable_customkey
    "

    echo $VARS
}

function getattributes()
{
    VARS=$(getvars)

    string=""
    retcode=0
    for VAR in $VARS; do
        varname=$(cut -d: -f1 <<< $VAR)
        varvalue=$(eval echo \$$varname)
        varob=$(cut -d: -f2 <<< $VAR)
        vardefault=$(cut -d: -f3 <<< $VAR)
        vartag=$(cut -d: -f4 <<< $VAR)

        if ! test -z "$varob"; then
            if ! test -z "$varvalue"; then
                string="$string $vartag=\"$varvalue\""
            elif ! test -z "$vardefault"; then
                string="$string $vartag=\"$vardefault\""
            else
                string="Var $varname must be defined."
                retcode=1
                break
            fi
        else
            if ! test -z "$varvalue"; then
                string="$string $vartag=\"$varvalue\""
            elif ! test -z "$vardefault"; then
                string="$string $vartag=\"$vardefault\""
            fi
        fi
    done

    echo $string
    return $retcode
}

function createdatastructure()
{
    local HOST=$1
    datapath=$SDIWEB/hosts/$HOST/
    mkdir -p $datapath
    for file in $(ls $HOOKS/*/*); do
        field=$(basename $(realpath $file))
        if ! test -f $datapath/$field.xml; then
            echo "<$field value=\"\" />" > $datapath/$field.xml
        fi
    done
    echo "<status value=\"OFFLINE\" class=\"red\" />" > $datapath/status.xml
}

function waitend()
{
    for pid in $*; do
        while ps --pid $pid &> /dev/null; do
                sleep 0.5
        done
    done
}

function closehost()
{
    local HOST=$1
    if test -f $PIDDIR/$HOST; then
        touch $TMPDIR/${HOST}_FINISH
        echo "exit 0" >> $CMDDIR/$HOST
        echo "exit 0" >> $CMDDIR/$HOST
        printf "Waiting $HOST tunnel finish... "
        waitend $(cat $PIDDIR/$HOST)
        printf "done\n"
    else
        printf "Host $HOST not running.\n"
    fi
}

function closeallhosts()
{
    touch $TMPDIR/SDIFINISH
    echo "exit 0" >> $CMDGENERAL
    echo "exit 0" >> $CMDGENERAL
    printf "Waiting tunnels to finish... "
    waitend $(cat $PIDDIR/* | paste -d' ' -s)
    printf "done\n"
}

function PRINT() 
{
    echo "$(date +%s) $1" >> $2
}

#Prototype of PARSE() function
function PARSE() 
{
    HOST=$1

    while read LINE; do
        FIELD=$(cut -d"+" -f1 <<< $LINE |tr '[:upper:]' '[:lower:]')
        DATA=$(cut -d"+" -f2- <<< $LINE)

        DATAPATHERR=$DATADIR/errors
        DATAPATH=$DATADIR/$HOST/$FIELD

        if ! source $PREFIX/commands-available/$FIELD.po 2> /dev/null; then
            mkdir -p $DATAPATHERR
            PRINT "$LINE" "$DATAPATHERR/$HOST"
        else
            mkdir -p $DATAPATH
            updatedata $DATA
            PRINT "$UPDATA" "$DATAPATH/$FIELD"
            if test $WEBMODE = true; then
                www $DATA
                ATTR=$(getattributes)
                if test $? == 0; then
                    WWWLINE="<$FIELD $ATTR />"
                    mkdir -p $SDIWEB/hosts/$HOST/
                    echo $WWWLINE > $SDIWEB/hosts/$HOST/${FIELD}.xml
                else
                    mkdir -p $DATAPATHERR
                    PRINT "Attribute error: $ATTR" "$DATAPATHERR/attrerror"
                fi
            fi

            #unset all variables used by script's
            for var in $(getvars); do
                unset $(cut -d: -f1 <<< $var)
            done
            unset DATA
        fi
    done
}

function SDITUNNEL()
{
    HOST=$1
    TMP=$(mktemp -p $TMPDIR $HOST.XXXXX)
    CMDFILE=$CMDDIR/$HOST
    while true; do
        rm -f $CMDFILE
        touch $CMDFILE
        (cat $HOOKS/onconnect.d/* 2>/dev/null; tail -f -n0 $CMDFILE & 
        tail -f -n0 $CMDGENERAL & jobs -p > $TMP) |
        ssh $SSHOPTS -l $SDIUSER $HOST "bash -s" | PARSE $HOST
        kill $(cat $TMP) &> /dev/null
        printf "STATUS+OFFLINE\n" | PARSE $HOST
        (test -f $TMPDIR/SDIFINISH || test -f $TMPDIR/${HOST}_FINISH) && break        
        sleep $(bc <<< "($RANDOM%600)+120")
    done
    rm -f $TMP
    rm -f $PIDDIR/$HOST
}

function LAUNCH () 
{
    #If there are SDI tunnels opened, the execution should be stopped
    pidsrunning=""
    for HOST in $(ls $PIDDIR); do
        PID=$(cat $PIDDIR/$HOST)
        if ps --pid $PID &> /dev/null; then
            pidsrunning="$pidsrunning $PID"
        fi
    done
    if ! test -z "$pidsrunning"; then
        echo "Some SDI tunnels still opened. Close them and try to run SDI again."
        echo "PIDS:$pidsrunning"
        exit 1
    fi

    rm -f $TMPDIR/*FINISH

    # Create file that will be used to send commands to all hosts 
    touch $CMDGENERAL

    #Open a tunnel for each host
    for HOST in $*; do
        echo $HOST
        test $WEBMODE = true && createdatastructure $HOST
        SDITUNNEL $HOST &
        echo $! > $PIDDIR/$HOST
        sleep $LAUNCHDELAY
    done
}

if test $# -eq 0  ; then
    echo "Usage:"
    echo "  $0 host1 [host2 [host3 [host... ]]]"
    exit 1
fi

if test $# -eq 0 ; then
    usage
    exit 1
fi

case $1 in
    --kill=?*)
        closehost $(echo $1| cut -d'=' -f2)
        exit 0
        ;;
    --killall)
        closeallhosts
        exit 0
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    -*)
        echo "Unknown option."
        usage
        exit 1
        ;;
esac

#Create directories
mkdir -p $TMPDIR
mkdir -p $PIDDIR
mkdir -p $CMDDIR
mkdir -p $DATADIR

#Start launching SDI tunnels
LAUNCH $*

if test $DAEMON == true; then
    exit 0
else
    printf "Waiting SDI Tunnels to finish"
    wait $(jobs -p)
    printf ".\n"
    exit 0
fi
