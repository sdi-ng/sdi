#############################################################
# SDI is an open source project.
# Licensed under the GNU General Public License v2.
#
# File Description:
#
#
#############################################################

#!/bin/bash
PREFIX=$(dirname $0)

eval $($PREFIX/configsdiparser.py $PREFIX/sdi.conf shell general)
if test $? != 0; then
    echo "ERROR: failed to load $PREFIX/sdi.conf file"
    exit 1
fi

# Function to update the sdi log.
# The log message contains the seconds since
# 1970 and the contents of $1 parameter
LOG()
{
    echo "$(date +%s) $1" >> $LOG
}

# Write $1 (string) into $2 (file) with the seconds since 1970
PRINT()
{
    echo "$(date +%s) $1" >> $2
}

# Create a directory and ensure that it is accessible, or exit SDI
SDIMKDIR()
{
    dir=$1
    if ! (mkdir -p $dir &&
          test -O $dir &&
          test -r $dir &&
          test -w $dir &&
          test -x $dir); then
        printf "Unable to create directory \"$dir\".\n"
        printf "Check if you are the owner of \"$dir\" and have r/w/x "
        printf "permissions to access it and then try to run SDI again.\n"
        return 1
    else
        return 0
    fi
}

# $1 - PID of process that is listening the fifo
# $2 - Name of fifo file. closefifo() will look for this file in $FIFODIR
closefifo()
{
    PIDFIFO=$1
    FIFO=$2
    test -d "/proc/${PIDFIFO}" && echo "exit exit exit" >> "${FIFODIR}/${FIFO}" &&
    waitend "${PIDFIFO}"
    rm -f "${FIFODIR}/${FIFO}"
}

# detects if sdi is running
issdirunning()
{
  for PID in $(find "${PIDDIRHOSTS}" "${PIDDIRSYS}" -type f \
      -exec cat {} \; 2>/dev/null); do
    test -d /proc/$PID && return 0
  done
  return 1
}

# removes sdi commands from cron
removecronconfig()
{
  crontab -l | grep -v "launchscripts.sh" | crontab -
  crontab -l | grep -v "sdictl --sync-data" | crontab -
}

# configures sdi commands into cron
configurecron()
{
  # first the basic scripts proccess
  script=$(realpath launchscripts.sh)
  cron="* * * * * $script minutely"
  cron="$cron\n0 * * * * $script hourly"
  cron="$cron\n0 0 * * * $script daily"
  cron="$cron\n0 0 1 * * $script montly"
  cron="$cron\n0 0 * * 0 $script weekly"

  # check if we must add the data sync
  if test "$USEFASTDATADIR" = "yes"; then
    script=$(realpath sdictl)
    cron="$cron\n20 */$DATASYNCINTERVAL * * * $script --sync-data"
  fi

  # add old cron info
  cron="$cron\n$(crontab -l| \
          egrep -v '(sdictl --sync-data|launchscripts.sh)'| uniq)"
  cron="$cron\n"

  # update the crontab
  printf "$cron" | crontab -
}
