#!/bin/bash

for arq in `ls /containerstoexecute/`; do
  docker import /containerstoexecute/$arq exec:$arq
  docker run -v /data/:/compartilhada -ti -d --name $arq -h $arq exec:$arq /inicia.sh $arq
  echo 1 > /containersrunning/$arq
  rm /containerstoexecute/$arq
done