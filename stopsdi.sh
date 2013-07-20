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
if ! isrunning; then
  echo "SDI is not running. Aborting."
  exit 1
fi

# prevent from creating new tunnels when killing tunnels
touch "${TMPDIR}/finish"

# send the finish message and a few exit 0 messages
# the finisheverything message
echo "finisheverything" >> "${CMDGENERAL}"
echo "exit 0" >> "${CMDGENERAL}"
printf "Sent message to finish all connections... waiting...\n"
sleep 30
echo "exit 0" >> "${CMDGENERAL}"
printf "Forced killing the main connection process... waiting...\n"
sleep 20
echo "exit 0" >> "${CMDGENERAL}"
printf "Did it again... waiting...\n"
sleep 20

# now real checking the process
printf "Something may still be running... cleaning up...\n";
TAILPIDS=$(cat "${PIDDIRHOSTS}/"*".tail" 2>/dev/null)
kill -9 ${TAILPIDS} 2>/dev/null
printf "Killed things that should had died before... waiting...\n"
sleep 20
TUNNELPIDS=$(cat "${PIDDIRHOSTS}/"*".sditunnel" 2>/dev/null)
kill -9 ${TUNNELPIDS} 2>/dev/null

# finish the services (nodejs main server)
printf "Finishing all servers and services... not waiting...\n"
kill -9 $(cat "${PIDDIRSYS}/runner.pid") 2>/dev/null

# kill server
kill -9 $(cat "${PIDDIRSYS}/node-server.pid")
node "${PREFIX}/server/sdi-server.js" &>>"${PREFIX}/sdi.log" &
  echo $! > "${PIDDIRSYS}/node-server.pid"

# looks like we are all done
printf "\nAll done.\n"
exit 0
