#include <iostream>
#include <stdio.h>
#include <fstream>
#include <string>
#include <string.h>
#include "socket.h"
#include "common.h"

using namespace std;

main(int argc, char *argv[]) {

    //string buffer;
    char buffer[BUFSIZ];
    int n;

    if (argc != 4) {
        ERROR("Usage: %s <port> <host to connect> <host to manage>\n",argv[0]);
        exit(1);
    }

    strcpy(buffer,argv[3]);
    strcat(buffer," ");
    n = strlen(buffer);

    // Create socket connection
    SocketClient sock(atoi(argv[1]),argv[2]);

    while (fgets(&buffer[n],BUFSIZ,stdin)) {
        sock.SendMessage(buffer);
    }
}
