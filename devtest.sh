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
HOST_CHOSEN=0
HOST_DESTINO=null

chose_host(){

    
    for CLASS in $CLASSES; do

    	printf "INICIO \n"

        if [ $HOST_CHOSEN -eq 0 ]; then

        	printf "DEBUG A \n"

            cat $CLASSESDIR/$CLASS | \
            while read HOST; do
				printf "DEBUG B ($HOST) \n"                
                # verifica se esta online
                IS_UP="$(tail -1 $DATADIR/$HOST/status | awk -F' ' '{print $2}' )"
                
                if [ $IS_UP = "ONLINE" ]; then
                	printf "DEBUG C \n"
                    # verifica se suporta docker
                    DOCKER="$(tail -1 $DATADIR/$HOST/checkdocker | awk -F' ' '{print $2}' )"
                    
                    if [ $DOCKER = "SUPPORT" ]; then
                    	printf "DEBUG D \n"
                        # verifica se esta abaixo do limite de containers por maquina
                        if [ ! -f $DATADIR/$HOST/".qtdcontainers" ]; then
                          	printf "DEBUG E ($HOST) \n"
                            HOST_CHOSEN=1
                            HOST_DESTINO=$HOST
                            printf "Host_chosen: $HOST_CHOSEN\n"
                            printf "DESTINO: "$HOST_DESTINO"\n"
                            #echo 1 > $DATADIR/$HOST/".qtdcontainers"
                            break
                        else
                        	printf "DEBUG F ($HOST) \n"
                        	QTD_CONT="$(cat $DATADIR/$HOST/".qtdcontainers")"   
                            if [ $QTD_CONT -lt $MAX_CONTAINERS_BY_HOST ];then
                            	printf "DEBUG G ($HOST) \n"
                                HOST_CHOSEN=1  
                                HOST_DESTINO=$HOST
                                let QTD_CONT=$QTD_CONT+1;
                                #echo $QTD_CONT > $DATADIR/$HOST/".qtdcontainers"
                                break
                            fi
                        fi            

                    fi
                fi           

            done

            printf "SAIU DEBUG A \n"
        	printf "Host_chosen: $HOST_CHOSEN\n"
        fi

        printf "FIM 1 \n"
        printf "Host_chosen: $HOST_CHOSEN\n"
    done
    printf "FIM 2 \n"
    printf "Host_chosen: $HOST_CHOSEN\n"
}



chose_host;
#printf "O container sera enviado para o cliente $HOST_DESTINO\n"

printf "DESTINO: "$HOST_DESTINO"\n"

if [ $HOST_CHOSEN -eq 1 ]; then 

    printf $HOST_DESTINO 

else

	printf "nada selecionado"

fi
printf "\n"
