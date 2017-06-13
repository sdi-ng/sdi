#!/bin/bash

exit 0

PREFIX=$(dirname $0)

if [ ! -e $PREFIX'/config' ]; then
    echo "ERROR: The $PREFIX/config  file does not exist or can not be accessed"
    exit 1
fi

source $PREFIX'/config'

for arq in `ls /containersrunning/`; do

  docker_status="$(docker inspect -f {{.State.Running}} $arq)"

  if [ "$docker_status" = "false" ]; then
  	#ja terminou de executar
  	docker logs $arq > /data/$arq.log

    printf "0" > docker logs $arq > /data/$arq.status
  	
    #ve se gerou saida, se nao gerou provavelmente tem erro...
  	if [ ! -e "/data/"$arq ] ; then
  		echo "SDI ERROR: Container nao gerou saida..." >> /data/$arq.log
  	else
      echo "SDI FINISHED: Done..." >> /data/$arq.log
    fi

    dmesg | tail -20 > /data/$arq.logsys

  	rm /containersrunning/$arq
  	docker rm $arq
  	docker rmi $arq
  else
    printf "1" > docker logs $arq > /data/$arq.status
  fi
done