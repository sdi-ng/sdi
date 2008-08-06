function generateclasspage()
{
    CLASS=$1

    HEADER="<!--#include virtual=\"html/header.html\"-->"
    FOOTER="<!--#include virtual=\"html/footer.html\"-->"
    PAGETYPE="<div class=\"hide\" id=\"pagetype\">single</div>"

    TITLE="$CLASSNAME: $(echo $CLASS |tr '_' ' ')"

    PAGE=$PREFIX/$WWWDIR/$CLASS/index.shtml
 
    echo $HEADER > $PAGE
    echo $PAGETYPE >> $PAGE
    printf "$SDIBAR\n" >> $PAGE
    generatetablestruct "$TITLE" >> $PAGE
    loadtablescripts "$TITLE" "$CLASS" >> $PAGE
    
    echo $FOOTER >> $PAGE
}

function generatetablestruct()
{
    FILE=$PREFIX/$SDIWEB/html/table.html
    TID="$(tr -d ' ' <<<$1)"
    
    sed "s/{TID}/$TID/g; s/{COLUMNS}/$DEFAULTCOLUMNS/g" $FILE |
    sed "s/{TITLE}/$TITLE/g"
}

function loadtablescripts()
{
    TID="$(tr -d ' ' <<<$1)"
    CLASS=$2

    printf "<script type=\"text/javascript\">\n"
    printf "create_table_from_xml('$CLASS.xml', '$TID', '${TID}_div');\n"
    printf "</script>\n"
}

# vim:tabstop=4:shiftwidth=4:encoding=utf-8:expandtab
