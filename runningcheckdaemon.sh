#!/bin/bash

PREFIX=$(dirname $0)

if [ ! -e $PREFIX'/sdi.conf' ]; then
    echo "ERROR: The $PREFIX/sdi.conf  file does not exist or can not be accessed"
    exit 1
fi

source $PREFIX'/sdi.conf'

#test if config is loaded
if test $? != 0; then
    echo "ERROR: failed to load $PREFIX/sdi.conf file (status.sh)"
    exit 1
fi

CONTAINERS=$(ls $CONTAINER_POOL)
CONTAINERSNUM=$(ls $CONTAINER_POOL | wc -l)


COUNT=0
for CONTAINER in $CONTAINERS; do
    
    STATUS_CONT="$(cat $CONTAINER_POOL/$CONTAINER/status)"
    
    if [ $STATUS_CONT = "SENT-RUNNING" ] || [ $STATUS_CONT = "ERROR-TRYING-AGAIN" ]; then
        printf "Verificando container $CONTAINER \n"

        HOST_DEST="$(cat $CONTAINER_POOL/$CONTAINER/destination_host)"

        rsync -q $HOST_DEST:/data/$CONTAINER $CONTAINER_POOL/$CONTAINER/result > /dev/null
        rsync -q $HOST_DEST:/data/$CONTAINER.log $CONTAINER_POOL/$CONTAINER/execution_log > /dev/null
        
        if [ -s $CONTAINER_POOL/$CONTAINER/result ]; then
            echo "EXECUTED-OK" > $CONTAINER_POOL/$CONTAINER/status

            # remove os arquivos da maquina que executou
            echo "rm /data/$CONTAINER /data/$CONTAINER.log" >> cmds/$HOST_DEST

        else

            #tem log, entao tem erro
            if [ -s $CONTAINER_POOL/$CONTAINER/execution_log ]; then

                ATTEMPTS="$(cat $CONTAINER_POOL/$CONTAINER/attempts)"

                if [ $ATTEMPTS -eq 3 ]; then
                    #ja foram feitas 3 tentativas de execucao, erro fatal
                    echo "FATAL-ERROR" > $CONTAINER_POOL/$CONTAINER/status
                    echo "rm /data/$CONTAINER /data/$CONTAINER.log" >> cmds/$HOST_DEST
                else
                    #alguma coisa para tentar novamente vai aqui (enviar outro host, etc...)
                    echo "ERROR-TRYING-AGAIN" > $CONTAINER_POOL/$CONTAINER/status
                    ATTEMPTS="$(($ATTEMPTS + 1))" 
                    echo $ATTEMPTS > $CONTAINER_POOL/$CONTAINER/attempts
                    echo "rm /data/$CONTAINER /data/$CONTAINER.log" >> cmds/$HOST_DEST

                    #manda outro host
                fi
            fi
            
            #se nao tem log espera proxima verificacao
           
        fi 

    fi

done
