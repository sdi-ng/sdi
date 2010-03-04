#include <iostream>
#include <errno.h>
#include "socket.h"
#include "common.h"

#define QUEUESIZE 5

using namespace std;

SocketClient::SocketClient(int port, string h) {

    struct sockaddr_in RemoteAddress;
    struct hostent *DNSRegister;
    const char* hostname = h.c_str();

    if((DNSRegister = gethostbyname(hostname)) == NULL){
      ERROR("Unable to get server address\n");
      exit(1);
    }

    bcopy((char *)DNSRegister->h_addr, (char *)&RemoteAddress.sin_addr,
       DNSRegister->h_length);
    RemoteAddress.sin_family = AF_INET;
    RemoteAddress.sin_port = htons(port);

    if((sock_send=socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        ERROR("%s\n",strerror(errno));
        exit(2);
    }

    if(connect(sock_send, (struct sockaddr *) &RemoteAddress,
               sizeof(RemoteAddress)) < 0) {
        ERROR("%s\n",strerror(errno));
        exit(3);
    }
}

void SocketClient::SendMessage(string data) {

    if(write(sock_send, data.c_str(), data.size()) != (int)data.size()) {
        ERROR("%s\n",strerror(errno));
        exit(1);
    }
}

SocketClient::~SocketClient() {
    close(sock_send);
}


SocketServer::SocketServer() {

    struct sockaddr_in LocalAddress;
    struct hostent *DNSRegister;
    int port = 18193;
    char HostName[10] = "localhost";

    if ((DNSRegister = gethostbyname(HostName)) == NULL){
        ERROR("Unable to get the IP of localhost\n");
        exit (1);
    }

    LocalAddress.sin_port = htons(port);
    LocalAddress.sin_family = AF_INET;
    bcopy ((char *) DNSRegister->h_addr, (char *) &LocalAddress.sin_addr,
             DNSRegister->h_length);

    if ((sock_listen = socket(AF_INET,SOCK_STREAM,0)) < 0){
        ERROR("%s\n",strerror(errno));
        exit(2);
    }

    if (bind(sock_listen, (struct sockaddr *) &LocalAddress,
            sizeof(LocalAddress)) < 0) {
        ERROR("%s\n",strerror(errno));
        exit(3);
    }

    if ( listen(sock_listen, QUEUESIZE)!=0 ) {
        ERROR("%s\n",strerror(errno));
        exit(4);
    }
}

char* SocketServer::GetMessage() {

    unsigned int aux, n;
    char *buffer = (char*) malloc(BUFSIZ);
    struct sockaddr_in ClientAddress;

    aux = sizeof(LocalAddress);
    if ( (sock_answer=accept(sock_listen, (struct sockaddr *) &ClientAddress,
             &aux)) < 0) {
        ERROR("%s\n",strerror(errno));
        exit(4);
    }
    if ( (n=read(sock_answer, buffer, BUFSIZ)) < 0 ) {
        ERROR("%s\n",strerror(errno));
        exit(5);
    }
    buffer[n+1] = '\0';
    DEBUG("I got a message ----> %s\n", buffer);
    // TODO: return an appropriate message to client
    write(sock_answer, buffer, n+1);
    close(sock_answer);
    return buffer;
}

SocketServer::~SocketServer() { }
