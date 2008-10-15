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
    printf "Ending sendfile... "
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
    touch $TMPDIR/SDIFINISH
    echo 'killchilds $$' >> $CMDGENERAL
    echo "exit 0" >> $CMDGENERAL
    echo "exit 0" >> $CMDGENERAL
    closesdiprocs
    printf "Waiting tunnels to finish... "
    waitend $(find $PIDDIRHOSTS -type f -exec cat {} \; 2> /dev/null)
    printf "done\n"
}

# Update the information about how many hosts are in the $1 state
function updatecnt() {
    webstatecount="$STATEDIR/$1-count.txt"
    webstatestatus="$STATEDIR/$1-status.xml"
    op=$2
    summaryphrase=$3
    nhosts=$(cat $webstatecount)
    if test "$op" = "sub" && test $nhosts -gt 0; then
        ((nhosts=nhosts-1))
    else
        ((nhosts=nhosts+1))
    fi
    printf "$nhosts\n" > $webstatecount
    printf "<$1>$summaryphrase</$1>\n" $nhosts > $webstatestatus
}

# Save the states of the remote hosts.
function savestate()
{
    (tail -f -n0 $SFIFO & echo $! > $PIDDIRSYS/fifo.pid) |
    while read HOST PSTATE PSTATETYPE; do

        if test "$PSTATE" = "exit"; then
            kill $(cat $PIDDIRSYS/fifo.pid)
            break
        fi

        local WEBSTATEXML="$STATEDIR/$PSTATETYPE.xml"

        if ! test -f "$WEBSTATEXML"; then
            LOG "ERROR: file $WEBSTATEXML not found."
            continue
        elif ! source $SHOOKS/$PSTATETYPE; then
            LOG "ERROR: failure to load $SHOOKS/$PSTATETYPE"
            continue
        elif ! getstateinfo; then
            LOG "ERROR: failure to load getstateinfo (in $SHOOKS/$PSTATETYPE)"
            continue
        else
            if test -z "$PSTATE" || test "$PSTATE" == false; then
                # Remove $HOST entry from $WEBSTATEXML
                if grep -q "hosts\/$HOST.xml\"" $WEBSTATEXML; then
                    sed -ie "/hosts\/$HOST.xml\"/d" $WEBSTATEXML
                    # Decreases in 1 the amount of hosts in this state
                    if ! test -z "$SSUMARY"; then
                        updatecnt $PSTATETYPE sub "$SSUMARY"
                    fi
                fi
            else
                # Add new host entry for this state in $WEBSTATXML
                tag="<\!--#include virtual=\"../hosts/$HOST.xml\"-->"
                if ! grep -q "$tag" $WEBSTATEXML; then
                    sed -ie "/--NEW--/i\\\t$tag" $WEBSTATEXML
                    # Increases in 1 the amount of hosts in this state
                    if ! test -z "$SSUMARY"; then
                        updatecnt $PSTATETYPE add "$SSUMARY"
                    fi
                fi
            fi
        fi
        unset SSUMARY
    done
}

# Create the structure of files that will be used to manage
# the states of the remote hosts
function createstatestructure()
{
    for state in $SHOOKS/*; do
        if ! source $state || ! getstateinfo &> /dev/null; then
            LOG "ERROR: failure to load state $state"
            return 1
        elif test -z "$SSUMARY"; then
            LOG "ERROR: state $state: \$SUMARY must be set in $state"
        elif test -z "$SDEFCOLUMNS"; then
            LOG "ERROR: state $state: \$SDEFCOLUMNS must be set in $state"
        elif test -z "$STITLE"; then
            LOG "ERROR: state $state: \$STITLE must be set in $state"
        else
            state=$(basename $state)
            cat <<EOF > $STATEDIR/$state.xml
<table title="$STITLE" columns="$SDEFCOLUMNS">
    <!--#include virtual="../hosts/columns.xml"-->
    <!--NEW-->
</table>
EOF
            printf "0\n" > "$STATEDIR/$state-count.txt"
            printf "<$state>$SSUMARY</$state>\n" 0 >\
            "$STATEDIR/$state-status.xml"
        fi
    done
}

#Prototype of PARSE() function
function PARSE()
{
    HOST=$1

    while read LINE; do
        FIELD=$(cut -d"+" -f1 <<< $LINE |tr '[:upper:]' '[:lower:]')
        DATA=$(cut -d"+" -f2- <<< $LINE)

        DATAPATH=$DATADIR/$HOST

        if ! source $PREFIX/commands-available/$FIELD.po 2> /dev/null; then
            PRINT "$LINE" "$DATAPATH/$HOST.log"
        else
            mkdir -p $DATAPATH
            updatedata $DATA
            PRINT "$UPDATA" "$DATAPATH/$FIELD"
            if test $WEBMODE = true; then
                www $DATA
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
                    LOG "ATTR ERROR: $ATTR"
                fi
            fi

            #unset all variables used by script's
            for var in $(getvars); do
                unset $(cut -d: -f1 <<< $var)
            done
            unset DATA PSTATE PSTATETYPE
        fi
    done
}

function SDITUNNEL()
{
    HOST=$1
    TMP=$PIDDIRHOSTS/${HOST}_TUNNELPROCS
    touch $TMP
    CMDFILE=$CMDDIR/$HOST
    while true; do
        rm -f $CMDFILE
        touch $CMDFILE
        printf "STATUS+OFFLINE\n" | PARSE $HOST
        (cat $HOOKS/onconnect.d/* 2>/dev/null; tail -f -n0 $CMDFILE &
        tail -f -n0 $CMDGENERAL & jobs -p > $TMP) |
        ssh $SSHOPTS -l $SDIUSER $HOST "bash -s" 2>&1| PARSE $HOST
        kill $(cat $TMP) &> /dev/null
        printf "STATUS+OFFLINE\n" | PARSE $HOST
        (test -f $TMPDIR/SDIFINISH || test -f $TMPDIR/${HOST}_FINISH) && break
        sleep $(bc <<< "($RANDOM%600)+120")
    done
    rm -f $TMP
    rm -f $PIDDIRHOSTS/$HOST
}

function LAUNCH ()
{
    #If there are SDI tunnels opened, the execution should be stopped
    hostsrunning=""
    for HOST in $*; do
        if test -f $PIDDIRHOSTS/$HOST; then
            PID=$(cat $PIDDIRHOSTS/${HOST})
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

    # Create strucure of xml files for states managing
    test $WEBMODE = true && createstatestructure

    #Open a tunnel for each host
    for HOST in $*; do
        echo $HOST
        SDITUNNEL $HOST &
        echo $! > $PIDDIRHOSTS/${HOST}
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
for dir in $TMPDIR $PIDDIR $PIDDIRHOSTS $PIDDIRSYS $CMDDIR $DATADIR \
           $STATEDIR $HOOKS $SHOOKS $FIFODIR; do
    if ! mkdir -p $dir; then
        printf "Unable to create directory $dir. "
        printf "Check the permissions and try to run sdi again.\n"
        exit 1
    fi
done

#Create fifo that will be used to manage states
#and open function to read fifo
rm -f $SFIFO ; mkfifo $SFIFO
savestate & echo $! >> $TMPDIR/savestate.pid

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
