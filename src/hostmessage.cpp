#include <iostream>
#include <stdlib.h>
#include <string.h>
#include "hostmessage.h"

HostMessage::HostMessage(char* msg) {
    char* idxmsg = strchr(msg, ' ');
    int n = idxmsg - msg;
    int nend = strlen(msg)-n;

    host = (char*) malloc( n*sizeof(char)+1 );
    message = (char*) malloc( nend*sizeof(char)+1 );

    strncpy(host,msg,n);
    strncpy(message,&msg[n+1],nend);
    host[n] = '\0';
    message[strlen(msg)] = '\0';
}

HostMessage::~HostMessage() {
    free(host);
    free(message);
}
