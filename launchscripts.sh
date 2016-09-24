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

if ! source "${PREFIX}/misc.sh"; then
  echo "SDI(cron): failed to load ${PREFIX}/misc.sh"
  exit 1
fi

eval $("${PREFIX}/configsdiparser.py" "${PREFIX}/sdi.conf" shell general)
if test "$?" != 0; then
  LOG "CRON: failed to load sdi configuration file: ${PREFIX}/sdi.conf"
  exit 1
fi

PERIOD="$1"

# do not allow to execute the onconnect again
# (this is to avoid problems with the bootstrap command)
test "${PERIOD}" = "onconnect" && exit 0

if ! test -f "${CMDGENERAL}"; then
  LOG "CRON: file not found: ${CMDGENERAL}"
elif test -d "${HOOKS}/${PERIOD}.d"; then
  cat "${HOOKS}/${PERIOD}.d/"* >> "${CMDGENERAL}"
fi
