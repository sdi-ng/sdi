function generatesummary()
{
    FILE=$1

    HEADER="<!--#include virtual=\"html/header.html\"-->"
    FOOTER="<!--#include virtual=\"html/footer.html\"-->"
    PAGETYPE="<div class=\"hide\" id=\"pagetype\">summary</div>"

    PAGE=$WWWDIR/$FILE.shtml

    echo $HEADER > $PAGE
    echo $PAGETYPE >> $PAGE

    # select current summary on sdibar
    TMP=$(mktemp)
    STR="\"$FILE.shtml\""
    printf "$SDIBAR\n" > $TMP
    sed "s/$STR>/$STR selected=\"selected\">/g" $TMP >> $PAGE
    rm -f "$TMP"

    SUMMARYFILE="$PREFIX/summaries-available/$FILE"
    unset STATES
    source "$SUMMARYFILE"
    getsummaryinfo

    # create a holder to summary to text with a loading message
    printf "<div id=\"summary_container\">\n" >> $PAGE
    printf "<span id=\"summary_text\"><br />\n" >> $PAGE
    printf "<img src=\"img/loader.gif\" class=\"loading_image\" " >> $PAGE
    printf "alt=\"\" title=\"\" />\n" >> $PAGE
    printf "<span class=\"loading_message\"></span></span>\n" >> $PAGE

    # create a table environment for each state
    for STATE in ${STATES[@]}; do
        STATEFILE="$PREFIX/states-enabled/$STATE"
        source "$STATEFILE"
        unset STITLE SDEFCOLUMNS STABLE
        ${STATE}_getstateinfo

        # check if the table must be hidden
        if test "$STABLE" = false; then
            continue
        fi

        TITLE="$STITLE"
        DEFAULTCOLUMNS="$SDEFCOLUMNS"
        generatetablestruct "$TITLE" >> $PAGE
    done
    printf "</div>\n" >> $PAGE

    # generatetablestruct destroy with FILE, we must set it again
    FILE=$1

    # function of generateclasspage.sh
    loadlanguages >> $PAGE
    loadsummaryscripts $FILE >> $PAGE

    echo $FOOTER >> $PAGE
}

function loadsummaryscripts()
{
    FILE=$1

    printf "<script type=\"text/javascript\">\n"
    printf "create_summary_from_xml('$FILE.xml', 'summary_container');\n"
    printf "</script>\n"
}

# vim:tabstop=4:shiftwidth=4:encoding=utf-8:expandtab
