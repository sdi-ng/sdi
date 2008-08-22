BARHTML=$SDIWEB/html/sdibar.html
OPTIONS=""

function generatesdibar()
{
    add_summaries

    for TYPE in $CLASSESDIR/*; do
        add_option single "$CLASSNAME/$(basename $TYPE)"
    done
    
    sed "s#(PAGES)#${OPTIONS}#g" $BARHTML
}

function add_summaries()
{
    for SUMMARY in $(\ls $PREFIX/summaries-enabled/*); do
        source $SUMMARY
        getsummaryinfo
        add_option summary $SNAME $(basename $(realpath $SUMMARY))
        unset SNAME
    done
}

function add_option()
{
    if [ $1 == "summary" ]; then
        OPTIONS="${OPTIONS}    <option value=\"$3.html\">$2</option>\n"
    else
        NAME=$(basename $2)
        SHOW=$(echo $2 |tr '_' ' ')
        OPTIONS="${OPTIONS}    <option value=\"${NAME}/\">${SHOW}</option>\n"
    fi
}

# vim:tabstop=4:shiftwidth=4:encoding=utf-8:expandtab
