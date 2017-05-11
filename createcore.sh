#!/bin/bash

PREFIX=$(dirname $0)

if [ ! -e $PREFIX'/sdi.conf' ]; then
    echo "ERROR: The $PREFIX/sdi.conf  file does not exist or can not be accessed"
    exit 1
fi

source $PREFIX'/sdi.conf'

#test if config is loaded
if test $? != 0; then
    echo "ERROR: failed to load $PREFIX/sdi.conf file"
    exit 1
fi

enviacore(){

    for HOST in $*; do
        scp -r -q $PREFIX"/coresdi-client" $HOST:/
    done

}

CLASSES=$(ls $CLASSESDIR)
CLASSESNUM=$(ls $CLASSESDIR | wc -l)

printf "Sending core to clients...\n"
COUNT=0
for CLASS in $CLASSES; do
    
    ((COUNT++))
    
    HOSTS=$(awk -F':' '{print $1}' $CLASSESDIR/$CLASS)

    enviacore $HOSTS

    sleep $LAUNCHDELAY

done

printf "done\n"

sleep 1

printf "Sending commands to iniciatialize cron jobs...\n"

echo "bash /coresdi-client/enablecron.sh" >> $PREFIX"/cmds/general"

printf "done...\n"