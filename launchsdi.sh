#!/bin/bash

PREFIX=$(dirname $0)

if ! source $PREFIX/sdi.conf; then
    echo "ERROR: failed to load $PREFIX/sdi.conf file"
    exit 1
fi

# Customizable variables, please refer to sdi.conf to change these values
: ${DATADIR:=$PREFIX/data}
: ${PIDDIR:=$TMPDIR/pids}
: ${PIDDIRSYS:=$PIDDIR/system}
: ${SHOOKS:=$PREFIX/states-enabled}
: ${CLASSESDIR:=$PREFIX/CLASSES}
: ${CLASSNAME:=Class}
: ${WWWDIR:=$PREFIX/www}
: ${SDIWEB:=$PREFIX/sdiweb}
: ${HOSTCOLUMNNAME:="Host"}
: ${DEFAULTCOLUMNS:="Uptime"}

# define STATEDIR
STATEDIR=$WWWDIR/states

function create_links()
{
    FOLDERS[0]="html"
    FOLDERS[1]="javascript"
    FOLDERS[2]="css"
    FOLDERS[3]="img"
    FOLDERS[4]="langs"

    for FOLDER in ${FOLDERS[@]}; do
        ln -fs $(realpath $SDIWEB)/$FOLDER $1/ 2> /dev/null
    done

    if test "$2" = "class"; then
        ln -fs ../hosts $1/ 2> /dev/null
    fi
}

function createclassstructure()
{
    CLASS=$1

    mkdir -p $WWWDIR/$CLASS
    create_links $WWWDIR/$CLASS class
}

function createdatastructure()
{
    local HOST=$1
    DATAPATH=$WWWDIR/hosts/$HOST/
    mkdir -p $DATAPATH
    for FILE in $(ls $HOOKS/*/*); do
        FIELD=$(basename $(realpath $FILE))
        if ! test -f $DATAPATH/$FIELD.xml; then
            echo "<$FIELD value=\"\" />" > $DATAPATH/$FIELD.xml
        fi
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
            test -f "$STATEDIR/$state.xml" && continue
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

function getcolumns()
{
    COLUMNS=""
    FIELDS=""
    COMMANDS=$(\ls $PREFIX/commands-enabled/*/*)
    TEMP=$(mktemp -p $TMPDIR)

    i=0
    for FIELD in $COMMANDS; do
        echo "$(basename $FIELD):$FIELD"
        ((i++))
    done > $TEMP

    COMMANDS=$(cat $TEMP | cut -d":" -f1 | sort | uniq)
    for FIELD in $COMMANDS; do
        FIELDS="$FIELDS $(grep "$FIELD" $TEMP | cut -d":" -f2 | head -1)"
    done

    for FIELD in $FIELDS; do
        source $(realpath $FIELD).po
        getcolumninfo

        # add column to list
        if test $WEBINTERFACE = true; then
            FIELD=$(basename $(realpath $FIELD))
            COLNAME=$(tr ' ' '_' <<< $COLNAME)
            COLUMNS="$COLUMNS $FIELD:$COLNAME"
        fi
        unset WEBINTERFACE COLNAME
    done

    printf "$COLUMNS"
    rm $TEMP
}

# Create necessary folders
mkdir -p $TMPDIR
mkdir -p $PIDDIR
mkdir -p $WWWDIR/hosts
mkdir -p $CLASSESDIR
mkdir -p $STATEDIR

# Check if web mode is enabled
if test $WEBMODE = true; then
    source $SDIWEB/generatesdibar.sh
    source $SDIWEB/generateclasspage.sh
    source $SDIWEB/generatesummary.sh
    source $SDIWEB/generatexmls.sh

    mkdir -p $WWWDIR
    create_links $WWWDIR

    SDIBAR=$(generatesdibar)
    COLUMNS=$(getcolumns)

    # Create strucure of xml files for states managing
    printf "Creating states files... "
    createstatestructure
    printf "done\n"
else
    printf "$0: warning: web mode is disabled.\n"
fi

# Start runing tunnels for hosts
CLASSES=$(ls $CLASSESDIR)
CLASSESNUM=$(ls $CLASSESDIR |wc -l)
if test $CLASSESNUM -eq 0; then
    printf "ERROR: no class set. At least one class of hosts must be defined
    in $CLASSESDIR directory.\n"
    exit 1
fi

# Start sendfile deamon
DAEMON="$PIDDIRSYS/deamon.pid"
printf "Launching sendfile deamon... "
( (test -f $DAEMON && ! test -d /proc/$(cat $DAEMON) ) ||
(! test -f $DAEMON )) && bash $PREFIX/launchsendfile.sh
printf "done\n"

COUNT=0
for CLASS in $CLASSES; do
    ((COUNT++))

    printf "Starting $CLASS ($COUNT/$CLASSESNUM)...\n"
    sleep 0.5

    HOSTS=$(awk '{print $1}' $CLASSESDIR/$CLASS)

    # Generate sdiweb files
    if test $WEBMODE = true; then
        printf "\tCreating web files... "
        createclassstructure $CLASS
        generateclasspage $CLASS
        generatexmls $CLASS "$HOSTS"
        for HOST in $HOSTS; do
            createdatastructure $HOST
        done
        printf "done\n"
    fi

    # Launch the tunnels
    DAEMON=true bash launchsditunnel.sh "$HOSTS"

    sleep 0.5
done

# Generate summaries
if test $WEBMODE = true; then
    printf "Generating summaries... "
    for SUMMARY in $(\ls $PREFIX/summaries-enabled/* 2> /dev/null); do
        generatesummary $(basename $(realpath $SUMMARY))
    done
    printf "done\n"
fi

printf "All done.\n"
