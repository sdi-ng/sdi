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

case $1 in
    --image=?*)
        listahosts $(echo $1| cut -d'=' -f2)
        exit 0
        ;;
    *)
        echo "Unknown option."
        usage
        exit 1
        ;;
esac
