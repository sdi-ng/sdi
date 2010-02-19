SHELL:=/bin/bash
LIBS=-lpthread
BIN=sdicore
CFLAGS=-DDEBUGFLAG

all: socketclient sdicore

sdicore: sdicore.cpp sdicore.h socket.o common.h
	$(CXX) $(CFLAGS) $@.cpp -c
	$(CXX) $(CFLAGS) $(LIBS) $@.o socket.o -o $(BIN)

socket.o: socket.cpp socket.h
	$(CXX) $(CFLAGS) socket.cpp -c

socketclient: socketclient.c
	$(CC) $(CFLAGS) $@.c -o $@

clean:
	rm -f socketclient *.o $(BIN)
