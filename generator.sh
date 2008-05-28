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

test -f $PREFIX/wwwsdi.conf && source $PREFIX/wwwsdi.conf

#Customizable variables, please refer to wwwsdi.conf to change these values
: ${TYPEDIR:=$PREFIX/TYPES}
: ${TYPENAME:=Class}
: ${WWWDIR:=$PREFIX/www}
: ${DATADIR:=$PREFIX/coleta}
: ${TABLEATTRIBUTES:="border=\"1\""}

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
    bash generatesumary


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
    echo "<div id=\"${TID}_div\">"
    echo "<span id=\"${TID}_cols\"></span>"
    echo "<table class=\"sortable\" id=\"${TID}\" $TABLEATTRIBUTES>"
    printf "<tr>$COLUMNNAMES</tr>\n"
}

#we will receive a file containing a DNS style list of hosts
function generate()
{
    START="$(date +%X)"
    TMP=$(mktemp)
    exec > $TMP
    cat $PREFIX/html/header.html 
    echo "<h1>$TYPENAME: $(basename $1|tr '_' ' ')</h1>"
    starttable
    while read HOSTLINE; do
        printf "<tr>"
        for COLUMN in columns/*; do
            ESC=$(awk '{print $1}' <<< $HOSTLINE)
            DATA=$DATADIR/$ESC
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
    printf "$(basename $1): $START ..  $(date +%X)\n" >&2
}


main $*

# vim:tabstop=4:shiftwidth=4:encoding=utf-8:expandtab
