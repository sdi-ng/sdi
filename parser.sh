# This function defines and returns the vars available to users by API of
# SDI
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

function PARSE()
{
    HOST=$1

    SELF=/proc/self/task/*
    basename $SELF > $PIDDIRSYS/$HOST.parserpid

    # cache and reload control
    CACHE=""
    RELOAD=false

    # on signal reload parser obejects
    trap "RELOAD=true" USR1

    while read LINE; do
        LOG "PARSER $LINE"
        FIELD=$(cut -d"+" -f1 <<< $LINE |tr '[:upper:]' '[:lower:]')
        DATA=$(cut -d"+" -f2- <<< $LINE)

        DATAPATH=$DATADIR/$HOST
        test -d $DATAPATH || mkdir -p $DATAPATH

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
            unset ${FIELD}_updatedata ${FIELD}_www &&
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
    rm -f $PIDDIRSYS/$HOST.parserpid
}

