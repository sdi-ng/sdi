#!/bin/bash

for (( i = 0; i < 40; i++ )); do
	bash sdictl --container=/root/sdi-docker/tmp/container_teste
	#printf "teste...\n"
done