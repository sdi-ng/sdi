SHELL:=/bin/bash

all: sdi

sdi: socketclient

socketclient: socketclient.c
	$(CC) $@.c -o $@

clean:
	rm -f socketclient
