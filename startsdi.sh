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

# Check if SDI is already running
issdirunning &&
  echo "SDI is already running. Aborting." && exit 1

# Check if must use a fast data dir
if test "$USEFASTDATADIR" = "yes"; then
  SDIMKDIR "${DATADIR}" || exit 1
  SDIMKDIR "${FASTDATADIR}" || exit 1
  DATADIR="${FASTDATADIR}"
fi

# Create necessary folders
for DIR in $TMPDIR $PIDDIR $PIDDIRSYS $PIDDIRHOSTS $CMDDIR $DATADIR $HOOKS \
           $SHOOKS $LOCKDIR $WWWDIR/hosts $CLASSESDIR \
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
printf "Creating nodes database... "
rm -f "${NODEDB}" 2>/dev/null
declare -a ALLHOSTS
ID=0
for CLASS in $CLASSES; do
  HOSTS=$(awk -F':' '{print $1}' $CLASSESDIR/$CLASS)
  for HOST in ${HOSTS}; do
    ALLHOSTS[$ID]=$HOST
    echo "${ID}:${HOST}" >> "${NODEDB}"
    ((ID=ID+1))

    # also create the datadir
    DATAPATH="${DATADIR}/${HOST}"
    SDIMKDIR "${DATAPATH}" || exit 1
  done
done
printf "$ID nodes found.\n"
N=$ID


# set status to be offline
# try a few times (the node server may not be started yet)
setoffline(){
  OFFID=$1

  # write post data to temp file
  POSTFILE=`mktemp`
  echo -e "${OFFID}\nSTATUS+OFFLINE" > ${POSTFILE}

  CNT=0
  while true; do
    curl -s -k -u "${WSUSER}:${WSPASS}" -X POST \
      --data-binary @"${POSTFILE}" https://127.0.0.1:${WSPORT}
    test "$?" = 0 && break
    ((CNT=CNT+1))
    test "${CNT}" -gt 30 && (rm -f "${POSTFILE}"; return 1)
    sleep 0.5
  done
  rm -f "${POSTFILE}"
  return 0
}

# The sdi tunnel
sditunnel(){
  HOSTID=$1
  HOST=$2

  # the host log file (send stuff that comes through the tunnel
  HOSTLOG="${DATADIR}/${HOST}/${HOST}.log"

  # tail and self pids
  TAILPID="${PIDDIRHOSTS}/${HOST}.tail"
  TUNNNELPID="${PIDDIRHOSTS}/${HOST}.sditunnel"

  setoffline "${HOSTID}"
  test "$?" != 0 && return 1

  # start the tunnel
  printf "Connecting to ${HOST}\n"
  (
   echo "MYID=${HOSTID}";
   echo "WSUSER=\"${WSUSER}\"";
   echo "WSPASS=\"${WSPASS}\"";
   echo "WSADDR=\"https://${WSADDR}:${WSPORT}\"";
   cat $HOOKS/onconnect.d/*;
   tail -fq -n0 "${CMDGENERAL}" & echo $! > "${TAILPID}") | \
     ssh ${SSHOPTS} -p ${SSHPORT} -l ${SDIUSER} ${HOST} "bash -s" &>> "${HOSTLOG}"

  # Lost connection
  printf "Lost connection to ${HOST}\n"
  setoffline "${HOSTID}"

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
    # try to open a new tunnel
    for NODEID in $(seq 0 $(($N-1))); do
      TUNNELPID="${PIDDIRHOSTS}/${ALLHOSTS[$NODEID]}.sditunnel"
      if (! test -f "${TUNNELPID}") || (test -f "${TUNNELPID}" &&
          ! test -d /proc/$(cat "${TUNNELPID}")); then
            test -f "${TMPDIR}/finish" && break

        sditunnel "${NODEID}" "${ALLHOSTS[$NODEID]}" &
          echo $! > "${TUNNELPID}"

        sleep ${LAUNCHDELAY}
      fi
    done
    sleep 30
  done
}

# launch everything
printf "Starting SDI main services... "
> "${CMDGENERAL}"

# node server
PIDNODE="${PIDDIRSYS}/node-server.pid"

# kill current
test -f "${PIDNODE}" &&
  test -d /proc/$(cat "${PIDNODE}") &&
  kill -9 $(cat "${PIDNODE}") 2>/dev/null

# launch
node "${PREFIX}/server/sdi-server.js" &>>"${PREFIX}/sdi.log" &
  echo $! > "${PIDNODE}"

# remove finish file and start
rm -f "${TMPDIR}/finish" 2>/dev/null
runner &>>"${PREFIX}/sdi.log" &
printf "done.\n"

# configure cron to send automatically send commands to hosts
printf "Configuring crontab... "
configurecron &>/dev/null
printf "done.\n"

printf "\nAll done.\n"
