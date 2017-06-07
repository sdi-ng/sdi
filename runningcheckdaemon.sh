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

CLASSES=$(ls $CLASSESDIR)
CONTAINERS=$(ls $CONTAINER_POOL)
CONTAINERSNUM=$(ls $CONTAINER_POOL | wc -l)

chose_host(){

    HOST_CHOSEN=0;

    for CLASS in $CLASSES; do

        if [ $HOST_CHOSEN -eq 0 ]; then

            #printf "DEBUG A \n"

            cat $CLASSESDIR/$CLASS | \
            while read HOST; do
                #printf "DEBUG B ($HOST) \n"                
                # verifica se esta online
                IS_UP="$(tail -1 $DATADIR/$HOST/status | awk -F' ' '{print $2}' )"
                
                if [ $IS_UP = "ONLINE" ]; then
                    #printf "DEBUG C \n"
                    # verifica se suporta docker
                    DOCKER="$(tail -1 $DATADIR/$HOST/checkdocker | awk -F' ' '{print $2}' )"
                    
                    if [ $DOCKER = "SUPPORT" ]; then
                        #printf "DEBUG D \n"
                        # verifica se esta abaixo do limite de containers por maquina
                        if [ ! -f $DATADIR/$HOST/".qtdcontainers" ]; then
                            #printf "DEBUG E ($HOST) \n"
                            HOST_CHOSEN=1
                            HOST_DESTINO=$HOST
                            #printf "Host_chosen: $HOST_CHOSEN\n"
                            #printf "DESTINO: "$HOST_DESTINO"\n"
                            echo 1 > $DATADIR/$HOST/".qtdcontainers"
                            printf $HOST > $CONTAINER_POOL/$CONTAINER/"destination_host"
                            #printf "O container $CONTAINER vai para o host $HOST\n "
                            #printf $CONTAINER_POOL/$CONTAINER/"destination_host\n"
                            break
                        else
                            #printf "DEBUG F ($HOST) \n"
                            QTD_CONT="$(cat $DATADIR/$HOST/".qtdcontainers")"   
                            if [ $QTD_CONT -lt $MAX_CONTAINERS_BY_HOST ];then
                                #printf "DEBUG G ($HOST) \n"
                                HOST_CHOSEN=1  
                                HOST_DESTINO=$HOST
                                let QTD_CONT=$QTD_CONT+1;
                                echo $QTD_CONT > $DATADIR/$HOST/".qtdcontainers"
                                #printf "O container $CONTAINER vai para o host $HOST\n "
                                printf $HOST > $CONTAINER_POOL/$CONTAINER/"destination_host"
                                break
                            fi
                        fi            

                    fi
                fi           

            done

            
        fi


    done

     
}

# verifica execuções e libera slots de containers já executados...
for CONTAINER in $CONTAINERS; do
    
    STATUS_CONT="$(cat $CONTAINER_POOL/$CONTAINER/status)"
    
    #etapa responsavel pelo acompanhamento das execuções
    if [ $STATUS_CONT = "SENT-RUNNING" ] || [ $STATUS_CONT = "ERROR-TRYING-AGAIN" ]; then

        sleep $LAUNCHDELAY

        printf "Verificando container $CONTAINER \n"

        HOST_DEST="$(cat $CONTAINER_POOL/$CONTAINER/destination_host)"

        rsync -q $HOST_DEST:/data/$CONTAINER $CONTAINER_POOL/$CONTAINER/result > /dev/null
        rsync -q $HOST_DEST:/data/$CONTAINER.log $CONTAINER_POOL/$CONTAINER/execution_log > /dev/null
        
        if [ -s $CONTAINER_POOL/$CONTAINER/result ]; then
            echo "EXECUTED-OK" > $CONTAINER_POOL/$CONTAINER/status

            #diminui qtd de containers naquele host
            QTD_CONT="$(cat $DATADIR/$HOST_DEST/".qtdcontainers")" 
            let QTD_CONT=$QTD_CONT-1;
            echo $QTD_CONT > $DATADIR/$HOST_DEST/".qtdcontainers"

            # remove os arquivos da maquina que executou
            echo "rm /data/$CONTAINER /data/$CONTAINER.log" >> cmds/$HOST_DEST
            # remove o container, ja foi executado
            rm $CONTAINER_POOL/$CONTAINER/container

        else

            #tem log, entao tem erro
            if [ -s $CONTAINER_POOL/$CONTAINER/execution_log ]; then

                ATTEMPTS="$(cat $CONTAINER_POOL/$CONTAINER/attempts)"

                if [ $ATTEMPTS -eq 3 ]; then
                    #ja foram feitas 3 tentativas de execucao, erro fatal
                    echo "FATAL-ERROR" > $CONTAINER_POOL/$CONTAINER/status
                    echo "rm /data/$CONTAINER /data/$CONTAINER.log" >> cmds/$HOST_DEST
                    rm $CONTAINER_POOL/$CONTAINER/container

                    #diminui qtd de containers naquele host
                    QTD_CONT="$(cat $DATADIR/$HOST_DEST/".qtdcontainers")" 
                    let QTD_CONT=$QTD_CONT-1;
                    echo $QTD_CONT > $DATADIR/$HOST_DEST/".qtdcontainers"

                else
                    #alguma coisa para tentar novamente vai aqui (enviar outro host, etc...)
                    echo "ERROR-TRYING-AGAIN" > $CONTAINER_POOL/$CONTAINER/status
                    ATTEMPTS="$(($ATTEMPTS + 1))" 
                    echo $ATTEMPTS > $CONTAINER_POOL/$CONTAINER/attempts
                    echo "rm /data/$CONTAINER /data/$CONTAINER.log" >> cmds/$HOST_DEST

                    #diminui qtd de containers naquele host
                    QTD_CONT="$(cat $DATADIR/$HOST_DEST/".qtdcontainers")" 
                    let QTD_CONT=$QTD_CONT-1;
                    echo $QTD_CONT > $DATADIR/$HOST_DEST/".qtdcontainers"

                    #manda outro host
                    rm $CONTAINER_POOL/$CONTAINER/destination_host
                fi
            else


                TIME_INICIO="$(date -d "$(cat $CONTAINER_POOL/$CONTAINER/date)" +%s)"

                TIME_AGORA="$(date +%s)"

                TIME_LIMIT="$(cat $CONTAINER_POOL/$CONTAINER/timelimit)"

                DIFERENCA="$(expr $TIME_AGORA - $TIME_INICIO)"

                if [ $DIFERENCA > $TIME_LIMIT ]; then

                    ATTEMPTS="$(cat $CONTAINER_POOL/$CONTAINER/attempts)"

                    #passou do tempo limite de execucao
                    if [ $ATTEMPTS -eq 3 ]; then
                    #ja foram feitas 3 tentativas de execucao, erro fatal
                        echo "FATAL-ERROR" > $CONTAINER_POOL/$CONTAINER/status
                        echo "rm /data/$CONTAINER /data/$CONTAINER.log" >> cmds/$HOST_DEST
                        rm $CONTAINER_POOL/$CONTAINER/container

                        #diminui qtd de containers naquele host
                        QTD_CONT="$(cat $DATADIR/$HOST_DEST/".qtdcontainers")" 
                        let QTD_CONT=$QTD_CONT-1;
                        echo $QTD_CONT > $DATADIR/$HOST_DEST/".qtdcontainers"

                    else
                        #alguma coisa para tentar novamente vai aqui (enviar outro host, etc...)
                        echo "ERROR-TRYING-AGAIN" > $CONTAINER_POOL/$CONTAINER/status
                        ATTEMPTS="$(($ATTEMPTS + 1))" 
                        echo $ATTEMPTS > $CONTAINER_POOL/$CONTAINER/attempts
                        echo "rm /data/$CONTAINER /data/$CONTAINER.log" >> cmds/$HOST_DEST

                        #diminui qtd de containers naquele host
                        QTD_CONT="$(cat $DATADIR/$HOST_DEST/".qtdcontainers")" 
                        let QTD_CONT=$QTD_CONT-1;
                        echo $QTD_CONT > $DATADIR/$HOST_DEST/".qtdcontainers"

                        #manda outro host
                        rm $CONTAINER_POOL/$CONTAINER/destination_host

                    fi
                fi

            fi
            
            #se nao tem log espera proxima verificacao
           
        fi 

        sleep $LAUNCHDELAY

    fi

done

# envia novos containers
for CONTAINER in $CONTAINERS; do
    
    STATUS_CONT="$(cat $CONTAINER_POOL/$CONTAINER/status)"
      

    # etapa responsavel pelo envio dos containeres da fila
    if [ $STATUS_CONT = "IN-QUEUE" ] ; then

        DESTINO="$(cat $CONTAINER_POOL/$CONTAINER/destination_host)"

        #printf "DESTINO: '$DESTINO'\n"

        if [ -z "$DESTINO" ]; then
            #escolhe um host para processar o container
            chose_host;
        fi
        
        DESTINO="$(cat $CONTAINER_POOL/$CONTAINER/destination_host)"
        #printf $DESTINO"\n"

         if [ ! -z "$DESTINO" ]; then

            #send the container
            scp -q $CONTAINER_POOL/$CONTAINER/"container" $DESTINO:/containerstoexecute/$CONTAINER

            echo -e "SENT-RUNNING" > $CONTAINER_POOL/$CONTAINER/"status"

            #increment the total history execution of the destination host (for stats only)
            if [ ! -f $DATADIR/$HOST/"containers_executed" ]; then
                
                echo 1 > $DATADIR/$HOST/"containers_executed"
            else
                
                QTD_CONT="$(cat $DATADIR/$HOST/"containers_executed")"   
                let QTD_CONT=$QTD_CONT+1;
                echo $QTD_CONT > $DATADIR/$HOST/"containers_executed"
            fi   

        fi
    fi

    # etapa responsavel pelo envio dos containeres da fila
    if [ $STATUS_CONT = "ERROR-TRYING-AGAIN" ] ; then

        DESTINO="$(cat $CONTAINER_POOL/$CONTAINER/destination_host)"

        #printf "DESTINO: '$DESTINO'\n"

        if [ -z "$DESTINO" ]; then
            #escolhe um host para processar o container
            chose_host;
        fi
        
        DESTINO="$(cat $CONTAINER_POOL/$CONTAINER/destination_host)"
        #printf $DESTINO"\n"

         if [ ! -z "$DESTINO" ]; then

            #send the container
            scp -q $CONTAINER_POOL/$CONTAINER/"container" $DESTINO:/containerstoexecute/$CONTAINER

            echo -e "SENT-RUNNING" > $CONTAINER_POOL/$CONTAINER/"status"

            #increment the total history execution of the destination host (for stats only)
            if [ ! -f $DATADIR/$HOST/"containers_executed" ]; then
                
                printf 1 > $DATADIR/$HOST/containers_executed
            else
                
                QTD_CONTE="$(cat $DATADIR/$HOST/"containers_executed")"   
                let QTD_CONTE=$QTD_CONTE+1;
                printf $QTD_CONTE > $DATADIR/$HOST/containers_executed
            fi   

        fi
    fi
done

