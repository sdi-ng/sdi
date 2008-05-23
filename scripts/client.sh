#!/bin/bash
# client.sh
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

#this is default separator to make our greps EASIER
SEPARATOR='+'

function PRINT()
{
    HOUR="$(date +"%b %d %R")"
    printf "$HOUR $*\n"
}

function PARSECMD()
{
    COMMAND="$1"
    ARGS="$(sed -e "s/^$COMMAND//" <<< $*)"
    case "$COMMAND" in
        exit)
            PRINT "bye bye"
            sync
            sleep 1
            kill -9 $MAINPID
            ;;
        echo)
            PRINT "$ARGS"
            ;;
        *)
            PRINT "\"$COMMAND\": Not allowed"
            PRINT "ABORT. ERRO CATASTROFICO"
            sync
            sleep 1
            kill -9 $MAINPID
            ;;
    esac
}

function WAITCMD()
{
    while true; do
        read COMMAND
        PARSECMD $COMMAND
    done
}
function ALARM()
{
    while true;do
        (sleep 3600
        kill -s SIGALRM $1) || (PRINT "SIGALRM - ERRNO"; kill -9 $PPDID $$)
    done
}

function RUNDIAGNOSE()
{
    cd /root/SDI/SDI
    for SCRIPT in *; do
        source $SCRIPT
    done
}
function main()
{
    #This is specific case of AJUDA_REMOTA, when booting with INSTALATION
    #CD. We run things here because this CD does NOT have a good version of
    #bash, so TRAP and many other functions are not implemented
    if grep -q none <<< $(hostname); then 
        while true; do
            PRINT "VERSION+Ajuda_Remota"; 
            UPSEC=$(cat /proc/uptime| cut -d. -f1)
            ((UPDIAS= UPSEC/60/60/24))
            ((UPHORAS= UPSEC/60/60 - UPDIAS*24))
            ((UPMINUTES= UPSEC/60 - UPHORAS*60 - UPDIAS*24*60))
            PRINT "UPTIME+$UPDIAS days,$UPHORAS:$UPMINUTES"; 
            sleep 1800
        done
    fi
    trap RUNDIAGNOSE ALRM || (PRINT 'TRAP: NOT IMPLEMENTED ?'; exit 1)

    #Workaround to make apostrofe work. If we have some ' on the code it
    #will be ignored, this happens because of the way we implement scripts
    #retrieval
    sed -i -e "s/APOSTROFO/'/g" /root/SDI/SDI/*
    RUNDIAGNOSE
    ALARM $$ &
    export MAINPID="$! $PPID $$" 
    WAITCMD
}

main $*

# vim:tabstop=4:shiftwidth=4:encoding=utf-8:expandtab
