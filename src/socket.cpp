#include <iostream>
#include <errno.h>
#include "socket.h"
#include "common.h"

#define QUEUESIZE 5

using namespace std;

SocketClient::SocketClient(int port, string h) {

    struct hostent *DNSRegister;
    const char* hostname = h.c_str();

    if((DNSRegister = gethostbyname(hostname)) == NULL){
      ERROR("Unable to get server address\n");
      exit(1);
    }

    bcopy((char *)DNSRegister->h_addr, (char *)&RemoteAddress.sin_addr,
       DNSRegister->h_length);
    RemoteAddress.sin_family = DNSRegister->h_addrtype;
    RemoteAddress.sin_port = htons(port);

    if((sock_send=socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        ERROR("sc socket: %s\n",strerror(errno));
        exit(2);
    }
}

void SocketClient::SendMessage(string data) {
    const char *d = data.c_str();

    if(sendto(sock_send, d, strlen(d)+1, 0,
            (struct sockaddr *) &RemoteAddress,
            sizeof RemoteAddress) != strlen(d)+1) {
        ERROR("sendto: %s\n",strerror(errno));
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
    LocalAddress.sin_family = DNSRegister->h_addrtype;

    bcopy ((char *) DNSRegister->h_addr, (char *) &LocalAddress.sin_addr,
             DNSRegister->h_length);

    if ((sock_listen = socket(AF_INET,SOCK_DGRAM,0)) < 0){
        ERROR("socket %s\n",strerror(errno));
        exit(2);
    }

    if (bind(sock_listen, (struct sockaddr *) &LocalAddress,
            sizeof(LocalAddress)) < 0) {
        ERROR("bind %s\n",strerror(errno));
        exit(3);
    }
}

char* SocketServer::GetMessage() {

    unsigned int aux, n;
    char *buffer = (char*) malloc(BUFSIZ);
    struct sockaddr_in ClientAddress;

    aux = sizeof(LocalAddress);
    recvfrom(sock_listen, buffer, BUFSIZ, 0,
             (struct sockaddr *) &LocalAddress, &aux);
    DEBUG("I got a message(%d) --> %s\n", strlen(buffer),buffer);
    // TODO: return an appropriate message to client
    return buffer;
}

SocketServer::~SocketServer() { }
