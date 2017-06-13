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

# verifica execuções e libera slots de containers já executados...
for CONTAINER in $CONTAINERS; do
    
    STATUS_CONT="$(cat $CONTAINER_POOL/$CONTAINER/status)"
    
    # container rodando
    if [ $STATUS_CONT = "SENT-RUNNING" ]; then


        #somente para a simulação do tcc, remover depois
        if [ -e $CONTAINER_POOL/$CONTAINER/container ]; then
            rm $CONTAINER_POOL/$CONTAINER/container 
        fi

        HOST="$(cat $CONTAINER_POOL/$CONTAINER/destination_host)"

        docker_status="$(ssh $SSHOPTS $HOST docker inspect -f {{.State.Running}} $CONTAINER)"

        printf  "Docker status: $docker_status\n";

        #nao esta mais rodando
        if [ "$docker_status" = "false" ]; then

            # busca resposta
            result="$(ssh $SSHOPTS $HOST ls /data/ | grep $CONTAINER)"

            printf  "Result file: $result\n";

            if [ ! -z $result ]; then
                
                printf  "Entrou tem resultado!\n";

                # tem resultado, copia do host remoto
                scp -q -o LogLevel=QUIET $HOST:/data/$CONTAINER $CONTAINER_POOL/$CONTAINER/result
                logs="$(ssh $SSHOPTS $HOST docker logs $CONTAINER)"
                printf "$logs" > $CONTAINER_POOL/$CONTAINER/execution_log
                printf "EXECUTED-OK" > $CONTAINER_POOL/$CONTAINER/status
                if [ -e $CONTAINER_POOL/$CONTAINER/container ]; then
                    rm $CONTAINER_POOL/$CONTAINER/container 
                fi
                
            else
                printf  "Entrou não tem resultado!\n";
                # nao foi gerado resultado
                printf "FATAL-ERROR" > $CONTAINER_POOL/$CONTAINER/status
                logs="$(ssh $SSHOPTS $HOST docker logs $CONTAINER)"
                printf "$logs" > $CONTAINER_POOL/$CONTAINER/execution_log
                printf "Não foi gerada saida..." >> $CONTAINER_POOL/$CONTAINER/execution_log
                

            fi

            # define horário final da execução
            printf "$(date)" > $CONTAINER_POOL/$CONTAINER/datefinish

            # remove container, imagem e tudo mais da máquina cliente
            printf "Removendo tudo..."
            # docker rm -f $(docker ps -a -q)
            # docker rmi -f $(docker images -q)
            image="$(ssh $SSHOPTS $HOST docker images | grep $CONTAINER | awk -F' ' '{print $3}')"
            printf "docker rm -f $CONTAINER; docker rmi -f $image;" >> $PREFIX/cmds/$HOST

            printf "Removendo um das execuções..."

            # diminui um da quantidade containers sendo executados
             TIRA_UM $DATADIR/$HOST

        else
            printf "Verificando tempo\n"
            #esta rodando, verifica tempo limite
            CHECK_TIME $CONTAINER_POOL/$CONTAINER $CONTAINER $HOST

            # verifica se foi encerrado, se foi deleta tudo
            STATUS_CONT_TIME="$(cat $CONTAINER_POOL/$CONTAINER/status)"

            if [ $STATUS_CONT_TIME = "TIMEOUT" ]; then

                image="$(ssh $SSHOPTS $HOST docker images | grep $CONTAINER | awk -F' ' '{print $3}')"
                printf "docker rm -f $CONTAINER; docker rmi -f $image;" >> $PREFIX/cmds/$HOST

                TIRA_UM $DATADIR/$HOST

            fi


        fi

    fi # fim container rodando

    # container timeout
    if [ $STATUS_CONT = "TIMEOUT" ]; then

        #verifica quantidade de tentativas

        ATTEMPTS="$(cat $CONTAINER_POOL/$CONTAINER/attempts)"

        #passou do tempo limite de execucao
        if [ $ATTEMPTS -eq $EXECUTION_ATTEMPTS ]; then
            #limite foi extrapolado, remove o container pois não sera mais reenviado

            if [ -e $CONTAINER_POOL/$CONTAINER/container ]; then
                rm $CONTAINER_POOL/$CONTAINER/container 
            fi
        else
            #ainda tem execucão
            let ATTEMPTS=$ATTEMPTS+1; 
            echo $ATTEMPTS > $CONTAINER_POOL/$CONTAINER/attempts
            rm $CONTAINER_POOL/$CONTAINER/daterunning
            rm $CONTAINER_POOL/$CONTAINER/datefinish
            rm $CONTAINER_POOL/$CONTAINER/destination_host
            printf "IN-QUEUE" > $CONTAINER_POOL/$CONTAINER/status
        fi      

    fi

    # container timeout
    if [ $STATUS_CONT = "FATAL-ERROR" ]; then

        #verifica quantidade de tentativas

        ATTEMPTS="$(cat $CONTAINER_POOL/$CONTAINER/attempts)"

        #passou do tempo limite de execucao
        if [ $ATTEMPTS -eq $EXECUTION_ATTEMPTS ]; then
            #limite foi extrapolado, remove o container pois não sera mais reenviado
            if [ -e $CONTAINER_POOL/$CONTAINER/container ]; then
                rm $CONTAINER_POOL/$CONTAINER/container 
            fi
        else
            #ainda tem execucão
            let ATTEMPTS=$ATTEMPTS+1; 
            echo $ATTEMPTS > $CONTAINER_POOL/$CONTAINER/attempts
            rm $CONTAINER_POOL/$CONTAINER/daterunning
            rm $CONTAINER_POOL/$CONTAINER/datefinish
            rm $CONTAINER_POOL/$CONTAINER/destination_host
            printf "IN-QUEUE" > $CONTAINER_POOL/$CONTAINER/status
        fi      

    fi

done

