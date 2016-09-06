#############################################################
# SDI is an open source project.
# Licensed under the GNU General Public License v2.
#
# File Description:
#
#
#############################################################

SHELL:=/bin/bash

all: sdi

sdi: socketclient

socketclient: socketclient.c
	$(CC) $@.c -o $@

clean:
	rm -f socketclient
