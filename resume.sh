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

printf "Numero total de containeres: "$CONTAINERSNUM"\n"

executando=0;
finalizados=0;
erro=0;
fila=0;

COUNT=0
for CONTAINER in $CONTAINERS; do
    
    STATUS_CONT="$(cat $CONTAINER_POOL/$CONTAINER/status)"
    
    if [ $STATUS_CONT = "SENT-RUNNING" ] || [ $STATUS_CONT = "ERROR-TRYING-AGAIN" ]; then

        let executando=$executando+1;

    fi

    if [ $STATUS_CONT = "EXECUTED-OK" ]; then

        let finalizados=$finalizados+1;

    fi

    if [ $STATUS_CONT = "FATAL-ERROR" ]; then

        let erro=$erro+1;

    fi

    if [ $STATUS_CONT = "IN-QUEUE" ]; then

        let fila=$fila+1;

    fi

done

printf "Na fila de envio: "$fila"\n"
printf "Em execução: "$executando"\n"
printf "Executados com sucesso: "$finalizados"\n"
printf "Não executados (erro fatal): "$erro"\n"
