function generatesummary()
{
    FILE=$1

    HEADER="<!--#include virtual=\"html/header.html\"-->"
    FOOTER="<!--#include virtual=\"html/footer.html\"-->"
    PAGETYPE="<div class=\"hide\" id=\"pagetype\">summary</div>"

    PAGE=$PREFIX/$WWWDIR/$FILE.shtml

    echo $HEADER > $PAGE
    echo $PAGETYPE >> $PAGE
    printf "$SDIBAR\n" >> $PAGE
    printf "<div id=\"summary_container\"></div>\n" >> $PAGE

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
