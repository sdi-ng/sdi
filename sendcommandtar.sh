#!/bin/bash

PREFIX=$(dirname $0)

if [ ! -e $PREFIX'/sdi.conf' ]; then
    echo "ERROR: The $PREFIX/sdi.conf  file does not exist or can not be accessed"
    exit 1
fi

source $PREFIX'/sdi.conf'

#test if config is loaded
if test $? != 0; then
    echo "ERROR: failed to load $PREFIX/sdi.conf file (launchsditunnel.sh)"
    exit 1
elif ! source $PREFIX/misc.sh; then
    echo "ERROR: failed to load $PREFIX/misc.sh file (launchsditunnel.sh)"
    exit 1
elif ! source $PREFIX/parser.sh; then
    echo "ERROR: failed to load $PREFIX/parser.sh file (launchsditunnel.sh)"
    exit 1
elif ! source $PREFIX/sendfile.sh; then
    echo "WARNING: failed to load $PREFIX/sendfile.sh file"
    echo "WARNING: you will not be able to send files to hosts through SDI (fatal error)"
    exit 1
fi

usage()
{
    echo "Usage:"
    echo "  $0 [options]"
    echo "Options:"
    echo "  --container=/full/patch/container.tar.gz      Send and execute a docker container"
}


chose_host(){

    # verifica se esta online
    # verifica se suporta docker
    # sistema de controle se esta ocupado ou com X (X < limit) containers em execucao
    chose="$(cat .chose)"

    if [ $chose -eq '0' ];then
      HOST_DESTINO="10.132.111.184"
      echo 1 > .chose
    else 
      HOST_DESTINO="10.132.111.160"
      echo 0 > .chose
    fi
}


generate_id(){

    # Source: https://gist.github.com/earthgecko/3089509
    #
    # bash generate random alphanumeric string
    #

    # bash generate random 64 character alphanumeric string (upper and lowercase) and 
    NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)

    #check if pool folder exist
    if [ ! -d "$CONTAINER_POOL" ]; then
        mkdir $CONTAINER_POOL
        if [ ! -d "$CONTAINER_POOL" ]; then
            printf "ERRO: Pasta $CONTAINER_POOL não existe e não pode ser criada...\n"
            exit 1
        fi
    fi

    #check if the ticket is uniq
    while [ -d "$CONTAINER_POOL/$NEW_UUID" ]
    do
        NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
    done

}

sendtarcommand(){

    TARFILE=$1
    TIMELIMIT=$2

    #verifica se o container existe
    if [ ! -f $TARFILE ]; then
        echo "ERRO: O arquivo tar não existe ou não pode ser acessado..."
        exit 1
    fi

    #escolhe um host para processar o container
    #printf "Definindo cliente para envio...\n"
    chose_host;
    #printf "O container sera enviado para o cliente $HOST_DESTINO\n"

    #generate the ID of the container
    generate_id
    #printf "Ticket de acompanhamento: $NEW_UUID\n"
    printf $NEW_UUID"\n"

    #copia para a pasta do container no pool
    mkdir $CONTAINER_POOL/$NEW_UUID
    cp $TARFILE $CONTAINER_POOL/$NEW_UUID/"tarfile"

    #send the container
    scp -q $CONTAINER_POOL/$NEW_UUID/"tarfile" $HOST_DESTINO:/tarfiletoexecute/$NEW_UUID

    #insert the execution in the "bd"
    echo -e "$(date)" > $CONTAINER_POOL/$NEW_UUID/"date"
    echo -e $HOST_DESTINO > $CONTAINER_POOL/$NEW_UUID/"destination_host"
    echo -e "SENT-RUNNING" > $CONTAINER_POOL/$NEW_UUID/"status"
    echo -e 1 > $CONTAINER_POOL/$NEW_UUID/"attempts"
    echo -e $TIMELIMIT > $CONTAINER_POOL/$NEW_UUID/"timelimit"
}

case $1 in
    --tar=?*)
        case $2 in
            --tl=?*)
                TIMELIMIT=$(echo $2| cut -d'=' -f2)
                if [ $TIMELIMIT = "--" ]; then
                    printf "WARNING: Time limit option was not set! The default limit will be used (1 hour).\n"
                    TIMELIMIT=3600
                fi
                ;;
            *)
                printf "WARNING: Time limit option was not set! The default limit will be used (1 hour).\n"
                TIMELIMIT=3600
                ;;
        esac
        #printf "Time limit: "$TIMELIMIT" second(s)\n"
        sendtarcommand $(echo $1| cut -d'=' -f2) $TIMELIMIT
        exit 0
        ;;
    *)
        printf "Unknown option."
        usage
        exit 1
        ;;
esac
