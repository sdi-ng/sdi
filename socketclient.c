#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdlib.h>
#include <string.h>

main(int argc, char *argv[]) 

 {  int sock_descr;
    int NumBytesRecebidos;
    int port;
    struct sockaddr_in EnderecRemoto;
    struct hostent *RegistroDNS;
    char buffer[BUFSIZ+1];
    char NomeHost[10] = "localhost";
    char *data;

    if(argc != 3) {
      puts("Usage: <port> <data>");
      exit(1);
    }

    port = atoi(argv[1]);
    data = argv[2];

    if((RegistroDNS = gethostbyname(NomeHost)) == NULL){
      puts("Unable to get server address.");
      exit(1);
    }

    bcopy((char *)RegistroDNS->h_addr, (char *)&EnderecRemoto.sin_addr, 
       RegistroDNS->h_length);
    EnderecRemoto.sin_family = AF_INET;
    EnderecRemoto.sin_port = htons(port);

    if((sock_descr=socket(AF_INET, SOCK_STREAM, 0)) < 0) {
      puts("Unable to open socket.");
      exit(1);
    }

    if(connect(sock_descr, (struct sockaddr *) &EnderecRemoto,
sizeof(EnderecRemoto)) < 0) {
      puts("Unable to connect to server.");
      exit(1);
    } 

    if(write(sock_descr, data, strlen(data)) != strlen(data)){
      puts("Unable to send data."); 
      exit(1);
    }

    read(sock_descr, buffer, BUFSIZ);
    if (strlen(buffer) > 0) 
        printf("%s\n", buffer);
   
    close(sock_descr);
    exit(0);
}
