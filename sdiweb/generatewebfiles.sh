#!/bin/bash

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

    SDIMKDIR $WWWDIR/$CLASS || exit 1
    create_links $WWWDIR/$CLASS class
}

function createdatastructure()
{
    local HOST=$1
    DATAPATH=$WWWDIR/hosts/$HOST/
    SDIMKDIR $DATAPATH || exit 1
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
        STABLE="true"
        NAME=$(basename $state)
        if ! source $state || ! ${NAME}_getstateinfo &> /dev/null; then
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
            SDIMKDIR "$STATEDIR/$state"
            test -f "$STATEDIR/$state.xml" && continue
            cat <<EOF > $STATEDIR/$state.xml
<table title="$STITLE" columns="$SDEFCOLUMNS" showtable="$STABLE">
    <!--#include virtual="../hosts/columns.xml"-->
    <!--NEW-->
</table>
EOF
            echo "<$state>$SSUMARY</$state>" >\
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
        source $(realpath $FIELD).po 2>/dev/null
        test "$?" != 0 && continue
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

source $SDIWEB/generatesdibar.sh
source $SDIWEB/generateclasspage.sh
source $SDIWEB/generatesummary.sh
source $SDIWEB/generatexmls.sh

create_links $WWWDIR

SDIBAR=$(generatesdibar)
COLUMNS=$(getcolumns)

# Create all files
printf "Creating web files... "
for CLASS in $CLASSES; do
    HOSTS=$(awk '{print $1}' $CLASSESDIR/$CLASS)

    createclassstructure $CLASS
    generateclasspage $CLASS
    generatexmls $CLASS "$HOSTS"
    for HOST in $HOSTS; do
        createdatastructure $HOST
    done
done
printf "done\n"

# Generate summaries
printf "Generating summaries... "
for SUMMARY in $(\ls $PREFIX/summaries-enabled/* 2> /dev/null); do
    generatesummary $(basename $(realpath $SUMMARY))
done
printf "done\n"
