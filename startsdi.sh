#!/bin/bash

PREFIX=$(dirname $0)

eval $($PREFIX/configsdiparser.py $PREFIX/sdi.conf shell all)
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

isrunning()
{
    for PID in $(find $PIDDIRHOSTS -type f -exec cat {} \; 2> /dev/null); do
        test -d /proc/$PID && return 0
    done
    return 1
}

# Check if SDI is already running
isrunning &&
    echo "SDI is already running. Aborting." && exit 1

# define STATEDIR
STATEDIR=$WWWDIR/states

# Check if must use a fast data dir
if test "$USEFASTDATADIR" = "yes"; then
  SDIMKDIR "${DATADIR}" || exit 1
  SDIMKDIR "${FASTDATADIR}" || exit 1
  DATADIR="${FASTDATADIR}"
fi

# Create necessary folders
for DIR in $TMPDIR $PIDDIR $PIDDIRSYS $PIDDIRHOSTS $CMDDIR $DATADIR $HOOKS \
           $SHOOKS $LOCKDIR $WWWDIR/hosts $STATEDIR $CLASSESDIR \
           $NODEDBDIR; do
    SDIMKDIR ${DIR} || exit 1
done

# Start runing tunnels for hosts
CLASSES=$(ls $CLASSESDIR)
CLASSESNUM=$(ls $CLASSESDIR |wc -l)
if test $CLASSESNUM -eq 0; then
    printf "ERROR: no class set. At least one class of hosts must be defined
    in $CLASSESDIR directory.\n"
    exit 1
fi

# Check if web mode is enabled
if test $WEBMODE = true; then
    source $SDIWEB/generatewebfiles.sh
else
    printf "$0: warning: web mode is disabled.\n"
fi

# Create nodes database
#printf "Creating nodes database... "
#rm -f "${NODEDBDIR}"/* 2>/dev/null
#declare -a ALLHOSTS
#ID=0
#for CLASS in $CLASSES; do
#  HOSTS=$(awk -F':' '{print $1}' $CLASSESDIR/$CLASS)
#  for HOST in ${HOSTS}; do
#    ALLHOSTS[$ID]=$HOST
#    echo "$HOST" > "${NODEDBDIR}/${ID}"
#    echo "${ID}:${HOST}" >> "${NODEDBDIR}/list"
#    ((ID=ID+1))

    # also create the datadir
#    DATAPATH="${DATADIR}/${HOST}"
#    SDIMKDIR "${DATAPATH}" || exit 1
#  done
#done
#printf "$ID nodes found.\n"

# Lock configuration to the number of open tunnels
#OPENLOCK="${LOCKDIR}/opentunnels.lock"
#OPENCOUNT="${TMPDIR}/opentunnels.count"
#rm -Rf "${OPENLOCK}" 2>/dev/null
#rm -f "${TMPDIR}/finish" 2>/dev/null
#echo 0 > "${OPENCOUNT}"

# increase execution ID
#EXECUTIONID=$(cat "${PREFIX}/executionid")
#((EXECUTIONID=EXECUTIONID+1))
#echo "${EXECUTIONID}" > "${PREFIX}/executionid"
#printf "Execution ID is... ${EXECUTIONID}\n"

#getcntlock(){
#  while ! mkdir "${OPENLOCK}" 2>/dev/null; do sleep 0.1; done
#}

#releasecntlock(){
#  rm -Rf "${OPENLOCK}" 2>/dev/null
#}

# The sdi tunnel
sditunnel(){
    HOSTID=$1
    HOST=$2

    # the host log file (send stuff that comes through the tunnel
    HOSTLOG="${DATADIR}/${HOST}/${HOST}.log"

    # tail and self pids
    TAILPID="${PIDDIRHOSTS}/${HOST}.tail"
    TUNNNELPID="${PIDDIRHOSTS}/${HOST}.sditunnel"

    # Start the tunnel
    printf "Connecting to ${HOST}\n"
    (
     #echo "N=${N}";
     #echo "LOGN=${LOGN}";
     #echo "EXECUTIONID=${EXECUTIONID}";
     #echo "MYID=${HOSTID}";
     #echo "SSHKEY=\"$(cat ~/.ssh/id_dsa)\"";
     #echo "NODELIST=\"$(cat ~/sdi/nodedb/list)\"";
     echo "WSADDR=\"https://planetmon.inf.ufpr.br:12368\"";
     #bash ./sendvarcmd.sh $PREFIX/commands-available/{common,cis,bootstrap};
     cat $HOOKS/onconnect.d/*;
     #bash ./cmd.sh onconnect $HOOKS/onconnect.d/*;
     tail -fq -n0 "${CMDGENERAL}" & echo $! > "${TAILPID}") | \
        ssh ${SSHOPTS} -p ${SSHPORT} -l ${SDIUSER} ${HOST} "bash -s" &>> "${HOSTLOG}"

    # Lost connection
    printf "Lost connection to ${HOST}\n"
    #getcntlock
    #COUNT=$(cat "${OPENCOUNT}")
    #((COUNT=COUNT-1))
    #echo "${COUNT}" > "${OPENCOUNT}"
    #releasecntlock

    kill -9 $(cat "${TAILPID}") 2> /dev/null &&
      rm -f "${TAILPID}.tail" 2> /dev/null
    rm -f "${TUNNELPID}" 2>/dev/null
}

# Run forever to make sure we have logN connections
# (or at least are trying to open logN tunnels)
runner(){
    SELF=/proc/self/task/*
    basename $SELF > "${PIDDIRSYS}/runner.pid"

    while true; do
      test -f "${TMPDIR}/finish" && break
      #getcntlock
      #COUNT=$(cat "${OPENCOUNT}")
      #if test "${COUNT}" -lt "${LOGN}"; then
          # try to open a new tunnel
      for NODEID in $(seq 0 $(($N-1))); do
        #((NODEID=RANDOM%N))
        TUNNELPID="${PIDDIRHOSTS}/${ALLHOSTS[$NODEID]}.sditunnel"
        if (! test -f "${TUNNELPID}") || (test -f "${TUNNELPID}" &&
            ! test -d /proc/$(cat "${TUNNELPID}")); then
              test -f "${TMPDIR}/finish" && break

          sditunnel "${NODEID}" "${ALLHOSTS[$NODEID]}" &
            echo $! > "${TUNNELPID}"

          sleep ${LAUNCHDELAY}
          #((COUNT=COUNT+1))
          #echo "${COUNT}" > "${OPENCOUNT}"
          #break
        fi
      done
      #fi
      #releasecntlock
      sleep 30
    done
}

# launch everything
printf "Starting SDI main services..."
> "${CMDGENERAL}"

kill -9 $(cat "${PIDDIRSYS}/node-server.pid")
node "${PREFIX}/server/sdi-server.js" &>>"${PREFIX}/sdi.log" &
    echo $! > "${PIDDIRSYS}/node-server.pid"
runner &

printf "\nAll done.\n"
