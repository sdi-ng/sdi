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
    echo "  --image=/full/patch/image      Send a docker image and install in all hosts"
}

listahosts(){
    
    IMAGE=$1 
    CLASSES=$(ls $CLASSESDIR)
    CLASSESNUM=$(ls $CLASSESDIR | wc -l)

    #check if image exists and is acessible
    if [ ! -e $IMAGE ]; then
        echo "ERROR: The image $IMAGE does not exist or can not be accessed"
        exit 1
    fi

    printf "Iniciando envio da imagem...\n"

    echo "mkdir -p /tmp/sdiimages/" >> $CMDGENERAL

    COUNT=0
    for CLASS in $CLASSES; do
        
        ((COUNT++))
        
        printf "\nInserindo na fila os hosts da classe $CLASS ($COUNT/$CLASSESNUM)..."
        
        sleep $LAUNCHDELAY

        HOSTS=$(awk -F':' '{print $1}' $CLASSESDIR/$CLASS)

        enviaimagem $HOSTS

        printf "done\n"
        
        sleep $LAUNCHDELAY
    
    done

    printf "Fila criada com sucesso, aguarde a transferencia...\n"

}

enviaimagem(){

    FILEFIFO="$FIFODIR/sendfile.fifo"

    for HOST in $*; do
        #printf "$HOST $IMAGE /tmp/sdiimages/ >> $FILEFIFO\n" 
        echo "$HOST $IMAGE /tmp/sdiimages/" >> $FILEFIFO
    done

}

chose_host(){

    # verifica se esta online
    # verifica se suporta docker
    # sistema de controle se esta ocupado ou com X (X < limit) containers em execucao

    HOST_DESTINO="138.197.75.38"

}


generate_id(){

    # Source: https://gist.github.com/earthgecko/3089509
    #
    # bash generate random alphanumeric string
    #

    # bash generate random 64 character alphanumeric string (upper and lowercase) and 
    NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)

    #check if pool exist
    if [ ! -d "$CONTAINER_POOL" ]; then
        mkdir $CONTAINER_POOL
        if [ ! -d "$CONTAINER_POOL" ]; then
            printf "ERRO: Pool de containers não existe e não pode ser criada...\n"
            exit 1
        fi
    fi

    while [ -d "$CONTAINER_POOL/$NEW_UUID" ]
    do
        NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
    done

}

sendcontainer(){

    CONTAINER=$1

    #verifica se o container existe
    if [ ! -f $CONTAINER ]; then
        echo "ERRO: O container não existe ou não pode ser acessado..."
        exit 1
    fi

    #escolhe um host para processar o container
    printf "Definindo cliente para envio...\n"
    chose_host;
    printf "O container sera enviado para o cliente $HOST_DESTINO\n"

    #generate the ID of the container
    generate_id
    printf "Ticket de acompanhamento: $NEW_UUID\n"

    #copia para a pasta do container no pool
    mkdir $CONTAINER_POOL/$NEW_UUID
    cp $CONTAINER $CONTAINER_POOL/$NEW_UUID/"container.tar.gz"

    #send the container
    scp -q $CONTAINER_POOL/$NEW_UUID/"container.tar.gz" $HOST_DESTINO:/tmp/containerstoexecute/$NEW_UUID".tar.gz"

}

case $1 in
    --container=?*)
        sendcontainer $(echo $1| cut -d'=' -f2)
        exit 0
        ;;
    *)
        echo "Unknown option."
        usage
        exit 1
        ;;
esac
