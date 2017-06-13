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
        printf "coresdi->$HOST\n"
        scp -r -q -o StrictHostKeyChecking=no $PREFIX"/coresdi-client" $HOST:/
        sleep 0.5
    done

}

CLASSES=$(ls $CLASSESDIR)
CLASSESNUM=$(ls $CLASSESDIR | wc -l)

printf "\nSending core to clients..."
COUNT=0
for CLASS in $CLASSES; do
    
    ((COUNT++))
    
    HOSTS=$(awk -F':' '{print $1}' $CLASSESDIR/$CLASS)

    enviacore $HOSTS

    

done

printf "done\n"

printf "Setando permissoes de execucao do core..."

echo "chmod -R 777 /coresdi-client/" >> $PREFIX"/cmds/general"

printf "done\n"

printf "Sending commands to iniciatialize cron jobs..."

echo "bash /coresdi-client/enablecron.sh" >> $PREFIX"/cmds/general"

printf "done\n"