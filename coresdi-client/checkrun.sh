#!/bin/bash

for arq in `ls /containersrunning/`; do
  docker_status="$(docker inspect -f {{.State.Running}} $arq)"
  if [ $docker_status = "false" ]; then
  	#ja terminou de executar
  	docker logs $arq > /data/$arq.log

  	#ve se gerou saida, se nao gerou provavelmente tem erro...
  	if [ ! -e "/data/"$arq ] ; then
  		echo "SDI ERROR: Container nao gerou saida..." >> /data/$arq.log
  	else
      echo "SDI FINISHED: Done..." >> /data/$arq.log
    fi

  	rm /containersrunning/$arq
  	docker rm $arq
  	docker rmi $arq
  fi
done