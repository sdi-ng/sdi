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

usage()
{
    echo "Usage:"
    echo "  $0 [options]"
    echo "Options:"
    echo "  --ticket=TICKET      Show information about the execution of the container"
}



loaddata(){

    TICKET=$1

    #verifica se o container existe
    if [ ! -d $CONTAINER_POOL"/"$TICKET"/" ]; then
        printf "ERRO: Ticket invalido...\n"
        exit 1
    fi

    printf "Ticket: "$TICKET
    printf "\n"
    printf "Recebido em: "
    cat $CONTAINER_POOL"/"$TICKET"/date"
    printf "Tempo limite de execução (seg): "
    cat $CONTAINER_POOL/$TICKET/timelimit
    printf "Status: "
    cat $CONTAINER_POOL"/"$TICKET"/status"
    #printf "Executado pelo cliente: "
    #cat $CONTAINER_POOL"/"$TICKET"/destination_host"

    STATUS_CONT="$(cat $CONTAINER_POOL/$TICKET/status)"

    if [ $STATUS_CONT = "ERROR-TRYING-AGAIN" ]; then
        printf "Tentativas de Execucao: "
        cat $CONTAINER_POOL"/"$TICKET"/attempts"
        printf "Log: "
        cat $CONTAINER_POOL"/"$TICKET"/execution_log"
        printf "\n"
    fi

    if [ $STATUS_CONT = "FATAL-ERROR" ]; then
        printf "Tentativas de Execucao: "
        cat $CONTAINER_POOL"/"$TICKET"/attempts"
        printf "Log: "
        cat $CONTAINER_POOL"/"$TICKET"/execution_log"
        printf "Executado pelo cliente: "
        cat $CONTAINER_POOL"/"$TICKET"/destination_host"
        printf "\n"
    fi

    if [ $STATUS_CONT = "EXECUTED-OK" ]; then
        printf "Tentativas de Execucao: "
        cat $CONTAINER_POOL"/"$TICKET"/attempts"
        printf "Log: "
        cat $CONTAINER_POOL"/"$TICKET"/execution_log"
        printf "Arquivo de resposta: "
        printf $CONTAINER_POOL"/"$TICKET"/result"
        FILESIZE="$(stat -c%s $CONTAINER_POOL/$TICKET/result)"
        printf " ($FILESIZE bytes)\n"
        printf "Executado pelo cliente: "
        cat $CONTAINER_POOL"/"$TICKET"/destination_host"
        printf "\n"
    fi

}

case $1 in
    --ticket=?*)
        loaddata $(echo $1| cut -d'=' -f2)
        exit 0
        ;;
    *)
        echo "Unknown option."
        usage
        exit 1
        ;;
esac
