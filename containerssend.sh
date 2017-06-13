#!/bin/bash

PREFIX=$(dirname $0)

if [ ! -e $PREFIX'/sdi.conf' ]; then
    echo "ERROR: The $PREFIX/sdi.conf  file does not exist or can not be accessed"
    exit 1
fi

source $PREFIX'/sdi.conf'

#test if config is loaded
if test $? != 0; then
    echo "ERROR: failed to load $PREFIX/sdi.conf file (runnincheckdaemon.sh)"
    exit 1
fi

CLASSES=$(ls $CLASSESDIR)
CONTAINERS=$(ls $CONTAINER_POOL)
CONTAINERSNUM=$(ls $CONTAINER_POOL | wc -l)

CHOSE_HOST(){

    HOST_CHOSEN=0;

    for CLASS in $CLASSES; do

        #DESTI_HOST_T="$(cat $1/destination_host )"

        if [ ! -e $1/destination_host ]; then
            
            cat $CLASSESDIR/$CLASS | \
            while read HOST; do           

                # DESTI_HOST_T="$(cat $1/destination_host )"

                if [ ! -e $1/destination_host ]; then

                    # verifica se esta online
                    IS_UP="$(tail -1 $DATADIR/$HOST/status | awk -F' ' '{print $2}' )"
                    
                    if [ $IS_UP = "ONLINE" ]; then
                        # verifica se suporta docker
                        DOCKER="$(tail -1 $DATADIR/$HOST/checkdocker | awk -F' ' '{print $2}' )"
                        
                        if [ $DOCKER = "SUPPORT" ]; then
                            # verifica se esta abaixo do limite de containers por maquina
                            #if [ ! -f $DATADIR/$HOST/.qtdcontainers ]; then
                            #    echo 1 > $DATADIR/$HOST/.qtdcontainers
                            #    printf $HOST > $1/"destination_host"
                            #    break
                            #else
                            #    QTD_CONT="$(cat $DATADIR/$HOST/.qtdcontainers)"   
                            #    if [ $QTD_CONT -lt $MAX_CONTAINERS_BY_HOST ];then
                            #        let QTD_CONT=$QTD_CONT+1;
                            #        echo $QTD_CONT > $DATADIR/$HOST/.qtdcontainers
                            #        printf $HOST > $1/"destination_host"
                            #        break
                            #    fi
                            #fi

                            ATUAL_CONT="$(cat $PREFIX/.atualcont)"

                            #increment the total history execution of the destination host (for stats only)
                            if [ ! -f $DATADIR/$HOST/containers_executed ]; then    
                                echo 1 > $DATADIR/$HOST/containers_executed
                                echo 1 > $DATADIR/$HOST/.qtdcontainers
                                printf $HOST > $1/"destination_host"
                                break
                            else
                                QTD_CONT="$(cat $DATADIR/$HOST/containers_executed)"  
                                if [ $QTD_CONT -lt $ATUAL_CONT ]; then
                                    QTD_EXEC="$(cat $DATADIR/$HOST/.qtdcontainers)" 
                                    if [ $QTD_EXEC -lt $MAX_CONTAINERS_BY_HOST ];then
                                        let QTD_EXEC=$QTD_EXEC+1;
                                        echo $QTD_EXEC > $DATADIR/$HOST/.qtdcontainers
                                        printf $HOST > $1/"destination_host"
                                        let QTD_CONT=$QTD_CONT+1;
                                        echo $QTD_CONT > $DATADIR/$HOST/containers_executed
                                        break
                                    fi
                                    
                                fi
                            fi   

                        fi
                    fi           
                fi
            done

            
        fi


    done

     
}

SOMA_UM(){
    QTD_CONT="$(cat $1/.qtdcontainers)" 
    let QTD_CONT=$QTD_CONT+1;
    echo $QTD_CONT > $1/.qtdcontainers 
}

TIRA_UM(){
    QTD_CONT="$(cat $1/.qtdcontainers)" 
    let QTD_CONT=$QTD_CONT-1;
    echo $QTD_CONT > $1/.qtdcontainers
}



KILL_TIMEOUT(){

    printf "TIMEOUT" > $1/status
    printf "$(date)" > $1/datefinish
}


CHECK_TIME(){

    TIME_INICIO="$(date -d "$(cat $1/daterunning)" +%s)"

    TIME_AGORA="$(date +%s)"

    TIME_LIMIT="$(cat $1/timelimit)"

    DIFERENCA="$(expr $TIME_AGORA - $TIME_INICIO)"

    printf "INICIO: $TIME_INICIO Limite: $TIME_LIMIT Diferenca: $DIFERENCA\n"

    if [ $DIFERENCA -gt $TIME_LIMIT ]; then
        KILL_TIMEOUT $1 $2 $3
    fi
}

for OPT in "${SSHOPT[@]}"; do
    SSHOPTS="$SSHOPTS -o $OPT"
done

# envia novos containers
for CONTAINER in $CONTAINERS; do
    
    STATUS_CONT="$(cat $CONTAINER_POOL/$CONTAINER/status)"
      
    # etapa responsavel pelo envio dos containeres da fila
    if [ $STATUS_CONT = "IN-QUEUE" ] ; then

        #printf "DESTINO: '$DESTINO'\n"

        if [ ! -e $CONTAINER_POOL/$CONTAINER/destination_host ]; then
            #escolhe um host para processar o container
            CHOSE_HOST $CONTAINER_POOL/$CONTAINER;
        fi

        if [ -e $CONTAINER_POOL/$CONTAINER/destination_host ]; then

            DESTINO="$(cat $CONTAINER_POOL/$CONTAINER/destination_host)"

            printf "Enviando container $CONTAINER para o host $DESTINO\n "

            printf "$(date)" > $CONTAINER_POOL/$CONTAINER/daterunning

            #send the container
            scp -q $CONTAINER_POOL/$CONTAINER/container $DESTINO:/containerstoexecute/$CONTAINER

            printf "SENT-RUNNING" > $CONTAINER_POOL/$CONTAINER/status

           

        fi
    fi

done

