#!/bin/bash

PREFIX=$(dirname $0)

if [ ! -e $PREFIX'/sdi.conf' ]; then
    echo "ERROR: The $PREFIX/sdi.conf  file does not exist or can not be accessed"
    exit 1
fi

source $PREFIX'/sdi.conf'

#test if config is loaded
if test $? != 0; then
    echo "ERROR: failed to load $PREFIX/sdi.conf file"
    exit 1
elif ! source $PREFIX/misc.sh; then
    echo "ERROR: failed to load $PREFIX/misc.sh file"
    exit 1
fi

# check if realpath command is available
test -x "$(which realpath)" ||
    { printf "FATAL: \"realpath\" must be installed\n" && exit 1; }

# define STATEDIR
STATEDIR=$WWWDIR/states

# Create necessary folders
SDIMKDIR $TMPDIR || exit 1
SDIMKDIR $PIDDIR || exit 1
SDIMKDIR $PIDDIRSYS || exit 1
SDIMKDIR $WWWDIR/hosts || exit 1
SDIMKDIR $STATEDIR || exit 1
SDIMKDIR $FIFODIR || exit 1
SDIMKDIR $CLASSESDIR || exit 1

# Start runing tunnels for hosts
CLASSES=$(ls $CLASSESDIR)
CLASSESNUM=$(ls $CLASSESDIR | wc -l)

if test $CLASSESNUM -eq 0; then
    printf "ERROR: no class set. At least one class of hosts must be defined in $CLASSESDIR directory.\n"
    exit 1
fi

# Check if web mode is enabled
if test $WEBMODE = true; then

    source $SDIWEB/generatewebfiles.sh

    # Start states daemon
    printf "Launching states daemon... "
    bash $PREFIX/states.sh
    printf "done\n"

else

    printf "WARNING: web mode is disabled.\n"

fi

# Open socketdaemon
# PS: Sockets foram usados pelo vinicius, essa versão utilizará o SSH, não sockets para comunicação...
#$PREFIX/socketdaemon.py & disown

# Start sendfile deamon
DAEMON="$PIDDIRSYS/sendfiledaemon.pid"
printf "Launching sendfile deamon... "
if (test -f $DAEMON && ! test -d /proc/$(cat $DAEMON)) ||
   (! test -f $DAEMON); then

    bash $PREFIX/launchsendfile.sh
else
    printf "already running, "
fi
printf "done\n"

# Check if must use a fast dir or the disk
if test "$USEFASTDATADIR" = "yes"; then
    SDIMKDIR "$FASTDATADIR" || exit 1
else
    SDIMKDIR "$DATADIR" || exit 1
fi


# Start launching the tunnels
COUNT=0
for CLASS in $CLASSES; do
    ((COUNT++))
    printf "\nStarting $CLASS ($COUNT/$CLASSESNUM)...\n"
    sleep $LAUNCHDELAY

    HOSTS=$(awk -F':' '{print $1}' $CLASSESDIR/$CLASS)

    # Launch the tunnels
    DAEMON=true CLASS=$CLASS $CORESHELL $PREFIX/launchsditunnel.sh "$HOSTS"
    sleep $LAUNCHDELAY
done

#send the core to the clients
echo "DOCKER_REGISTRY_IP=$DOCKER_REGISTRY_IP" > $PREFIX/coresdi-client/config
bash $PREFIX/createcore.sh


#start docker registry if enable
if $DOCKER_REGISTRY = 'true'; then
    #fazer if pra ver se o container existe, se nao existe cria, se não so executa

    printf "\nInicializando Docker Registry (localhost:5000)..."

    if [ ! -f $TMPDIR/.dkregistry ]; then
        docker run -d -p 5000:5000 --name registry registry:2
        echo 1 > $TMPDIR/.dkregistry
    else
        docker start registry
    fi 

    echo "bash /coresdi-client/cfgdocker.sh" >> $CMDGENERAL
    
    printf "Docker Registry Done..."
else
    printf "WARNING: Docker Registry is not enabled. The function --createcontainer will not work!\n"
fi

printf "\nAll done.\n"
