#!/bin/bash

sdiroot=.

source $sdiroot/sdi.conf

CMDDIR=$sdiroot/cmds
HOOKS=$sdiroot/commands-enabled

SOURCE="$1"

cat $HOOKS/${SOURCE}.d/* >> $CMDDIR/general
