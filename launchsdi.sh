#!/bin/bash

PREFIX=$(dirname $0)

source $PREFIX/sdi.conf

# Customizable variables, please refer to sdi.conf to change these values
: ${DATADIR:=$PREFIX/data}
: ${CLASSESDIR:=$PREFIX/CLASSES}
: ${CLASSNAME:=Class}
: ${WWWDIR:=$PREFIX/www}
: ${SDIWEB:=$PREFIX/sdiweb}
: ${HOSTCOLUMNNAME:="Host"}
: ${DEFAULTCOLUMNS:="Uptime"}


function create_links()
{
    FOLDERS[0]="html"
    FOLDERS[1]="javascript"
    FOLDERS[2]="css"
    FOLDERS[3]="img"
    FOLDERS[4]="hosts"
    FOLDERS[5]="langs"

    for FOLDER in ${FOLDERS[@]}; do
        ln -s $(realpath $PREFIX/$SDIWEB)/$FOLDER $1/ 2> /dev/null
    done

    if test "$2" = "states"; then
        ln -s $(realpath $PREFIX/$SDIWEB)/states $1/ 2> /dev/null
    fi
}

function createclassstructure()
{
    CLASS=$1

    mkdir -p $WWWDIR/$CLASS
    create_links $WWWDIR/$CLASS
}

function createdatastructure()
{
    local HOST=$1
    DATAPATH=$SDIWEB/hosts/$HOST/
    mkdir -p $DATAPATH
    for FILE in $(ls $HOOKS/*/*); do
        FIELD=$(basename $(realpath $FILE))
        if ! test -f $DATAPATH/$FIELD.xml; then
            echo "<$FIELD value=\"\" />" > $DATAPATH/$FIELD.xml
        fi
    done
    if ! test -f "$DATAPATH/status.xml"; then
        echo "<status value=\"OFFLINE\" class=\"red\" />" > $DATAPATH/status.xml
    fi
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

# Create temporary and hosts folder
mkdir -p $TMPDIR
mkdir -p $SDIWEB/hosts

# Check if web mode is enabled
if test $WEBMODE = true; then
    source $PREFIX/$SDIWEB/generatesdibar.sh
    source $PREFIX/$SDIWEB/generateclasspage.sh
    source $PREFIX/$SDIWEB/generatesummary.sh
    source $PREFIX/$SDIWEB/generatexmls.sh

    mkdir -p $WWWDIR
    create_links $WWWDIR states

    SDIBAR=$(generatesdibar)
    COLUMNS=$(getcolumns)
else
    printf "$0: warning: web mode is disabled.\n"
fi

# Start sendfile deamon
printf "Launching sendfile deamon... "
bash $PREFIX/launchsendfile.sh
printf "done\n"

# Start runing tunnels for hosts
CLASSES=$(ls $CLASSESDIR)
CLASSESNUM=$(ls $CLASSESDIR |wc -l)
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
