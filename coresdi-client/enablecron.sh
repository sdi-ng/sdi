#!/bin/bash

echo -e " \n \
*  *  *  *  *  /coresdi-client/croncontainer.sh \n \
*  *  *  *  *  sleep 10 && /coresdi-client/croncontainer.sh \n \
*  *  *  *  *  sleep 20 && /coresdi-client/croncontainer.sh \n \
*  *  *  *  *  sleep 30 && /coresdi-client/croncontainer.sh \n \
*  *  *  *  *  sleep 40 && /coresdi-client/croncontainer.sh \n \
*  *  *  *  *  sleep 50 && /coresdi-client/croncontainer.sh \n \
*  *  *  *  *  /coresdi-client/checkrun.sh \n \
*  *  *  *  *  sleep 10 && /coresdi-client/checkrun.sh \n \
*  *  *  *  *  sleep 20 && /coresdi-client/checkrun.sh \n \
*  *  *  *  *  sleep 30 && /coresdi-client/checkrun.sh \n \
*  *  *  *  *  sleep 40 && /coresdi-client/checkrun.sh \n \
*  *  *  *  *  sleep 50 && /coresdi-client/checkrun.sh \n" > /var/spool/cron/crontabs/root