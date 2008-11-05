#!/bin/bash

PREFIX=$(dirname $0)

# try to load configuration and sendfile function
if ! source $PREFIX/sdi.conf; then
    echo "ERROR: failed to load $PREFIX/sdi.conf file"
    exit 1
elif ! source $PREFIX/misc.sh; then
    echo "ERROR: failed to load $PREFIX/misc.sh file"
    exit 1
elif ! source $PREFIX/sendfile.sh; then
    echo "WARNING: failed to load $PREFIX/sendfile.sh file"
    echo "WARNING: you will not be able to send files to hosts through SDI"
fi

# These are minimal configuration needed, user may overwrite any of them by
# defining at sdi.conf
: ${TIMEOUT:=240}
: ${KILLTOUT:=30}
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
: ${PIDDIRHOSTS:=$PIDDIR/hosts}
: ${PIDDIRSYS:=$PIDDIR/system}
: ${HOOKS:=$PREFIX/commands-enabled}
: ${SHOOKS:=$PREFIX/states-enabled}
: ${CMDGENERAL:=$CMDDIR/general}
: ${SDIUSER:=$USER}

#Customizable variables, please refer to wwwsdi.conf to change these values
: ${SDIWEB:=$PREFIX/sdiweb}
: ${WWWDIR:=$PREFIX/www}
: ${FIFODIR:=$TMPDIR/fifos}
: ${SFIFO:=$FIFODIR/states.fifo}
: ${WEBMODE:=true}
: ${SDIWEB:=$PREFIX/sdiweb}

: ${LAUNCHDELAY:=0.1}
: ${DAEMON:=false}

# define STATEDIR
STATEDIR=$WWWDIR/states

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
    echo "  --reload-po    Force a reload of parser objects file"
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

function removecronconfig()
{
    crontab -l | grep -v launchscripts.sh | crontab -
}

function configurecron()
{
    script=$(realpath launchscripts.sh)
    cron[0]="* * * * * $script minutely"
    cron[1]="\n0 * * * * $script hourly"
    cron[2]="\n0 0 * * * $script daily"
    cron[3]="\n0 0 1 * * $script montly"
    cron[4]="\n0 0 * * 0 $script weekly"
    cron[5]="\n$(crontab -l| grep -v launchscripts.sh | uniq)"
    cron[6]="\n"
    printf "${cron[*]}" | crontab -
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

# function used to kill the childs of a process
function killchilds()
{
    PID=$1
    CHILDS=$(ps --ppid $PID |awk 'NR>1{print $1}')
    if test -d /proc/$PID; then
        kill $PID
    fi
    for CHILD in $CHILDS; do
        killchilds $CHILD
    done
}

function waitend()
{
    iter=0
    for pid in $*; do
        if ps --ppid $pid 2> /dev/null | grep -q "sleep"; then
            killchilds $pid
        fi
        while test -d /proc/$pid; do
            if test $iter -ge $KILLTOUT; then
                printf "Forced kill signal on pid $pid\n"
                kill $pid
                break
            else
                (( iter = iter + 1 ))
            fi
            sleep 1
        done
    done
}

function notunnelisopen()
{
    for pid in $(find $PIDDIRHOSTS -type f -exec cat {} \; 2> /dev/null); do
        test -d /proc/$pid && return 1
    done
    return 0
}

function closesdiprocs()
{
    test -f $PIDDIRSYS/fifo.pid && pidfifo=$(cat $PIDDIRSYS/fifo.pid) &&
    test -d /proc/$pidfifo && echo "exit exit exit" >> $SFIFO
    printf "Removing cron configuration... "
    removecronconfig
    printf "done\n"
    printf "Waiting savestate to finish... "
    waitend $(cat $PIDDIRSYS/fifo.pid)
    printf "done\n"
    printf "Stopping SDI services... "
    kill $(cat $PIDDIRSYS/*) &> /dev/null
    printf "done\n"
}

function closehost()
{
    local HOST=$1
    if test -f $PIDDIRHOSTS/$HOST; then
        touch $TMPDIR/${HOST}_FINISH
        echo 'killchilds $$' >> $CMDDIR/$HOST
        echo "exit 0" >> $CMDDIR/$HOST
        sleep 15
        echo "exit 0" >> $CMDDIR/$HOST
        printf "Waiting $HOST tunnel finish... "
        waitend $(cat $PIDDIRHOSTS/$HOST)
        printf "done\n"
        printf "Blocking $HOST to receive files... "
        sendfile -b $HOST
        printf "done\n"
        if notunnelisopen; then
            printf "There are no more SDI tunnels open. "
            printf "SDI will be closed now.\n"
            closesdiprocs
        fi
    else
        printf "Host $HOST not running.\n"
    fi
}

function closeallhosts()
{
    printf "Waiting tunnels to finish... "
    touch $TMPDIR/SDIFINISH
    echo 'killchilds $$' >> $CMDGENERAL
    echo "exit 0" >> $CMDGENERAL
    sleep 15
    echo "exit 0" >> $CMDGENERAL
    waitend $(find $PIDDIRHOSTS -type f -exec cat {} \; 2> /dev/null)
    printf "done\n"
    closesdiprocs
}

#Prototype of PARSE() function
function PARSE()
{
    HOST=$1
    DATAPATH=$DATADIR/$HOST
    mkdir -p $DATAPATH

    SELF=/proc/self/task/*
    basename $SELF > $PIDDIRHOSTS/$HOST.parserpid

    # cache and reload control
    CACHE=""
    RELOAD=false

    # on signal reload parser obejects
    trap "RELOAD=true" USR1

    while read LINE; do
        FIELD=$(cut -d"+" -f1 <<< $LINE |tr '[:upper:]' '[:lower:]')
        DATA=$(cut -d"+" -f2- <<< $LINE)

        # unset functions if will force a reload
        test $RELOAD = true &&
            for FNC in $CACHE; do unset $FNC; done &&
            RELOAD=false && CACHE=""

        LOAD=0

        if ${FIELD}_updatedata $DATA 2> /dev/null; then
            # already loaded
            LOAD=1
        elif source $PREFIX/commands-available/$FIELD.po 2> /dev/null; then
            # check if command is enabled
            ENABLED=false
            for CMD in $(ls $HOOKS/*/*); do
                test $(basename $(realpath $CMD)) = $FIELD &&
                ENABLED=true && break
            done

            test $ENABLED = false &&
            PRINT "ERROR: $FIELD is not enabled." "$DATAPATH/$HOST.log" &&
            continue

            # now sourced
            LOAD=2
            CACHE="$CACHE ${FIELD}_updatedata"
        else
            PRINT "$LINE" "$DATAPATH/$HOST.log"
            continue
        fi

        # if just sourced, must run updatedata again
        test $LOAD = 2 && ${FIELD}_updatedata $DATA

        # run script functions
        PRINT "$UPDATA" "$DATAPATH/$FIELD"
        if test $WEBMODE = true; then
            ${FIELD}_www $DATA
            ATTR=$(getattributes)
            if test $? == 0; then
                WWWLINE="<$FIELD $ATTR />"
                mkdir -p $WWWDIR/hosts/$HOST/
                echo $WWWLINE > $WWWDIR/hosts/$HOST/${FIELD}.xml
                if ! test -z "$PSTATETYPE"; then
                    for state in $PSTATETYPE; do
                        pstate=$(cut -d':' -f2 <<< $state)
                        pstatetype=$(cut -d':' -f1 <<< $state)
                        test -z "$pstate" && pstate="false"
                        echo "$HOST" "$pstate" "$pstatetype" >> $SFIFO
                    done
                fi
            else
                PRINT "ATTR ERROR ON $FIELD: $ATTR" "$DATAPATH/$HOST.log"
            fi
        fi

        # unset all variables used by script's
        for VAR in $(getvars); do
            unset $(cut -d: -f1 <<< $VAR)
        done
        unset DATA PSTATE PSTATETYPE
    done
    rm -f $PIDDIRHOSTS/$HOST.parserpid
}

function SDITUNNEL()
{
    HOST=$1
    CMDFILE=$CMDDIR/$HOST

    SELF=/proc/self/task/*
    basename $SELF > $PIDDIRHOSTS/$HOST.sditunnel
    SELF=$(cat $PIDDIRHOSTS/$HOST.sditunnel)

    while true; do
        rm -f $CMDFILE
        touch $CMDFILE
        (printf "STATUS+OFFLINE\n";
        (cat $HOOKS/onconnect.d/* 2>/dev/null;
         tail -fq -n0 --pid=$SELF $CMDFILE $CMDGENERAL) |
        ssh $SSHOPTS -l $SDIUSER $HOST "bash -s" 2>&1;
        printf "STATUS+OFFLINE\n") | PARSE $HOST
        (test -f $TMPDIR/SDIFINISH || test -f $TMPDIR/${HOST}_FINISH) && break
        sleep $(bc <<< "($RANDOM%600)+120")
    done
    rm -f $PIDDIRHOSTS/$HOST.sditunnel
}

function LAUNCH ()
{
    #If there are SDI tunnels opened, the execution should be stopped
    hostsrunning=""
    for HOST in $*; do
        if test -f $PIDDIRHOSTS/$HOST.sditunnel; then
            PID=$(cat $PIDDIRHOSTS/$HOST.sditunnel)
            if test -d /proc/$PID; then
                hostsrunning="$hostsrunning $HOST"
            fi
        fi
    done
    if ! test -z "$hostsrunning"; then
        echo "Some SDI tunnels still opened. Close them and try to run SDI again."
        printf "\tHosts:$hostsrunning\n"
        exit 1
    fi

    rm -f $TMPDIR/*FINISH

    # Create file that will be used to send commands to all hosts
    touch $CMDGENERAL

    #Open a tunnel for each host
    for HOST in $*; do
        echo $HOST
        SDITUNNEL $HOST &
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
    --reload-po)
        printf "Sending signal to parsers... "
        for PARSERPID in $(cat $PIDDIRHOSTS/*.parserpid); do
            kill -USR1 $PARSERPID 2> /dev/null
        done
        printf "done\nParser objects will be reloaded.\n"
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
for dir in $TMPDIR $PIDDIR $PIDDIRHOSTS $PIDDIRSYS $CMDDIR $DATADIR \
           $STATEDIR $HOOKS $SHOOKS $FIFODIR; do
    SDIMKDIR $dir || exit 1
done

#Start launching SDI tunnels
LAUNCH $*

#Initiate crontab
configurecron

if test $DAEMON == true; then
    exit 0
else
    printf "Waiting SDI Tunnels to finish"
    wait $(jobs -p)
    printf ".\n"
    exit 0
fi
