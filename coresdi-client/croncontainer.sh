#!/bin/bash

PREFIX=$(dirname $0)

if [ ! -e $PREFIX'/config' ]; then
    echo "ERROR: The $PREFIX/config  file does not exist or can not be accessed"
    exit 1
fi

source $PREFIX'/config'

qtd_executando="$(docker ps | grep imagename | wc -l)"

for arq in `ls /containerstoexecute/`; do

	if [ $qtd_executando -lt $MAX_CONTAINERS_BY_HOST ]; then 

		docker import /containerstoexecute/$arq exec:$arq
	 	docker run -v /data/:/compartilhada -ti -d --name $arq -h $arq exec:$arq /inicia.sh $arq
	  	echo 1 > /containersrunning/$arq
	  	rm /containerstoexecute/$arq
	  	
	fi

done
