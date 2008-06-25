#!/bin/bash
# generator.sh
# Copyright (C) 2008 - Centro de Computacao Cientifica e Software Livre -
# Departamento de Informatica - Universidade Federal do Parana - C3SL/UFPR
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
# USA.

PREFIX=.

if test -z "$CONFFILE"; then
    test -f $PREFIX/wwwsdi.conf && source $PREFIX/wwwsdi.conf
else
    source $CONFFILE || exit $?
fi

#Customizable variables, please refer to wwwsdi.conf to change these values
: ${TYPEDIR:=$PREFIX/TYPES}
: ${TYPENAME:=Class}
: ${WWWDIR:=$PREFIX/www}
: ${DATADIR:=$PREFIX/coleta}
: ${TABLEATTRIBUTES:="border=\"0\""}
: ${GENERATESUMMARY:=false}
: ${HISTORY:=true}
: ${HISTORYFILEFORMAT:="%Y%m%d%H%M"}

#Global variable, to avoid multiple generation of names
COLUMNNAMES=

main()
{
    NETSTAT="$(netstat -n --tcp --ip|grep ':22'|grep ESTAB)"
    printf "Generating:\n"
    printf "  ColumnNames"
    generatecolumnnames
    echo "."

    for TYPE in $TYPEDIR/*; do
        generate $TYPE &
        sleep 5
    done
    #printf "Waiting Generations"
    wait $(jobs -p)
    test "$GENERATESUMMARY" == "true" && bash generatesumary


}

function generatecolumnnames()
{
    for NAME in $PREFIX/columns/*; do
        source $NAME
        COLUMNNAMES="${COLUMNNAMES}$(getcolumnname)"
    done
}

function starttable()
{
    TID=$RANDOM
    echo "<div class=\"table_bar\" id=\"${TID}_bar\">
    <h3><a href=\"javascript:table_expand('${TID}');\" id=\"${TID}_expand\">
    <img src=\"img/expandUP.jpg\" /></a> $1</h3>
    <div class=\"bar_right\">
    <a href=\"#\" onmouseover=\"show_menu('${TID}_cols');\">
    Selecionar colunas <img src=\"img/columns.jpg\" /></a>
    <div class=\"hide\" id=\"${TID}_cols\" onmouseout=\"hide_menu(event, this);\">ID,Cidade,Escola,Status,Uptime</div>
    </div></div>
    <div id=\"${TID}_div\">
    <div id=\"${TID}_load\" class=\"loading\"></div>
    <table class=\"sortable\" style=\"display: none;\" id=\"${TID}\" $TABLEATTRIBUTES>"

    printf "<tr>$COLUMNNAMES</tr>\n"
}

#we will receive a file containing a DNS style list of hosts
function generate()
{
    START="$(date +%X)"
    TMP=$(mktemp)
    exec > $TMP
    cat $PREFIX/html/header.html 
    TITLE="$TYPENAME: $(basename $1|tr '_' ' ')"
    starttable "${TITLE}"
    while read HOSTLINE; do
        printf "<tr>"
        for COLUMN in columns/*; do
            HOSTID=$(awk '{print $1}' <<< $HOSTLINE)
            DATA=$DATADIR/$HOSTID
            source $COLUMN
            printf "$(getcolumn "$HOSTLINE")"
        done
        printf "</tr>\n"
    done < $1 
    echo "</table>"
    echo "</div>"
    echo "--<br/>"
    echo "Last Modified: <i>$(date)</i>"
    cat $PREFIX/html/footer.html 
    chmod a+r $TMP
    mv "$TMP" "$WWWDIR/$(basename $1)/index.html"
    if test "$HISTORY" = "true"; then
        FileEND=$(date +"$HISTORYFILEFORMAT")
        cp "$WWWDIR/$(basename $1)/index.html"{,.$FileEND}
    fi
    printf "$(basename $1): $START ..  $(date +%X)\n" >&2
}


main $*

# vim:tabstop=4:shiftwidth=4:encoding=utf-8:expandtab
