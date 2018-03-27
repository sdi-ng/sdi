#!/bin/bash

# ----------------------------------------------------------------------------------------------------------------
#
# This script searches machines on a specified network.
# An SSH connection attempt is made. If the connection is successful, the machine is added to the SDI.
# Usage: XX1.XX2.XX3.XX4 N1 N2 -> The script will search from XX1.XX2.XX3.N1 to XX1.XX2.XX3.N2. 
#
# Vagner 19/01/2017 11:49
#
# ----------------------------------------------------------------------------------------------------------------

if [ -z $1 ];then
    echo -e "Parametros incorretos! Informe o endereco principal da rede e o intervalo\nExemplo: 192.168.0.1 2 10"
    exit 0
fi

if [ -z $2 ];then
    echo -e "Parametros incorretos! Informe o endereco principal da rede e o intervalo\nExemplo: 192.168.0.1 2 10"
    exit 0
fi

if [ -z $3 ];then
    echo -e "Parametros incorretos! Informe o endereco principal da rede e o intervalo\nExemplo: 192.168.0.1 2 10"
    exit 0
fi



OIFS=$IFS
IFS='.'
network=($1)
IFS=$OIFS

base=${network[0]}.${network[1]}.${network[2]}.

echo Iniciando busca...

COUNTER=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YEL='\033[1;33m'
NC='\033[0m'

for i in `seq $2 $3`;
do
  
  # test conection
  #ssh -q -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=no root@$base$i  exit
  ssh -q -o BatchMode=yes -i /home/vagner/.ssh/chave_sdi -o ConnectTimeout=2 -o StrictHostKeyChecking=no root@$base$i  exit

  if [ $? -ne 0 ]
  then
    echo -e ${RED}Não foi possivel conectar ao ip $base$i${NC}
  else
    # AJUS: AQUI PRECISA SER FINALIZADO, para pegar o nome da pasta das classes do arquivo de configuracoes e criar a pasta se necessario...
    if [ -e CLASSES/$base$i ] 
    then 
      echo -e ${YEL}$base$i conectado com sucesso, porem ja faz parte do SDI, ignorado...${NC}
    else
      ((COUNTER++))
      echo $base$i >> CLASSES/autoinsert
      echo -e ${GREEN}$COUNTER: $base$i conectado com sucesso... Adicionado ao SDI...${NC} 
    fi
    
  fi
done  

echo -e $COUNTER maquinas encontradas e adicionadas... 
