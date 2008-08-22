function generatexmls()
{
    CLASS=$1
    HOSTS=$2
    
    generatecolumnsxml
    generateclassxml $CLASS "$HOSTS" > $WWWDIR/$CLASS/$CLASS.xml
    generatehostsxml $CLASS "$HOSTS"
    generatesummariesxml
}

function generateclassxml()
{
    CLASS=$1
    HOSTS=$2

    printf "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
    printf "<class name=\"$CLASS\">\n"
    printf "<!--#include virtual=\"hosts/columns.xml\"-->\n"

    for HOST in $HOSTS; do
        printf "<!--#include virtual=\"hosts/$HOST.xml\"-->\n"
    done

    printf "</class>\n"
}

function generatehostsxml()
{
    CLASS=$1
    HOSTS=$2

    for HOST in $HOSTS; do
        XML="    <host name=\"$HOST\">\n"
        XML="$XML        <hostname value=\"$HOST\" />\n"
        for COL in $COLUMNS; do
            COL=$(cut -d":" -f1 <<< $COL)
            XML="$XML        <!--#include virtual=\"$HOST/$COL.xml\"-->\n"
        done
        XML="$XML    </host>\n"
        printf "$XML" > $SDIWEB/hosts/$HOST.xml
    done
}

function generatecolumnsxml()
{
    XML="    <host name=\"columns\">\n"
    XML="$XML       <hostname value=\"$HOSTCOLUMNNAME\" />\n" 
    for COL in $COLUMNS; do
        VALUE=$(cut -d":" -f2 <<< $COL | tr '_' ' ')
        COL=$(cut -d":" -f1 <<< $COL)
        XML="$XML       <$COL value=\"$VALUE\" />\n" 
    done
    XML="$XML    </host>\n"
    printf "$XML" > $SDIWEB/hosts/columns.xml
}

function generatesummariesxml()
{
    for SUMMARY in $(\ls $PREFIX/summaries-enabled/*); do
        source $SUMMARY
        getsummaryinfo

        SUMMARY=$(basename $(realpath $SUMMARY))
        XML="<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
        XML="$XML<summary name=\"$SUMMARY\">\n"

        XML="$XML   <data>\n"
        for STATE in ${STATES[@]}; do
            XML="$XML<!--#include virtual=\"states/$STATE-status.xml\"-->\n"
        done
        XML="$XML   </data>\n"

        for STATE in ${STATES[@]}; do
            XML="$XML<!--#include virtual=\"states/$STATE.xml\"-->\n"
        done

        XML="$XML</summary>\n"
        printf "$XML" > $WWWDIR/$SUMMARY.xml

        unset STATES
    done
}

# vim:tabstop=4:shiftwidth=4:encoding=utf-8:expandtab
