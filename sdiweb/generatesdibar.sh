BARHTML=$SDIWEB/html/sdibar.html
OPTIONS=""

function generatesdibar()
{
    if [ "$GENERATESUMMARY" == "true" ]; then
        add_option sumary SUMARIO
    fi

    for TYPE in $CLASSESDIR/*; do
        add_option single "$CLASSNAME/$(basename $TYPE)"
    done
    
    sed "s#(PAGES)#${OPTIONS}#g" $BARHTML
}

function add_option()
{
    if [ $1 == "sumary" ]; then
        LOWER=$(echo $2 |tr '[:upper:]' '[:lower:]')
        OPTIONS="${OPTIONS}    <option value=\"${LOWER}.html\">$2</option>\n"
    else
        NAME=$(basename $2)
        SHOW=$(echo $2 |tr '_' ' ')
        OPTIONS="${OPTIONS}    <option value=\"${NAME}/\">${SHOW}</option>\n"
    fi
}

# vim:tabstop=4:shiftwidth=4:encoding=utf-8:expandtab
