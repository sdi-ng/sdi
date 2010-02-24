#ifndef __SOCKET_H
#define __SOCKET_H

#include <iostream>
#include <stdio.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netdb.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>

using namespace std;

// This class provides a simple interface to open a socket and get
// messages from it
class SocketServer {
    public:
        SocketServer();
        ~SocketServer();
        char* GetMessage();
    private:
        int sock_listen, sock_answer;
        struct sockaddr_in LocalAddress, ClientAddress;
};

#endif