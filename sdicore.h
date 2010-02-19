#ifndef SDI_CORE_H
#define SDI_CORE_H

#include <list>
#include <semaphore.h>
#include "socket.h"

using namespace std;

#define MAXCONSUMER 100;

// Separates msg into two elements: host and message
class HostMessage {
    public:
        HostMessage(char* msg);
        ~HostMessage();
        char* GetHost() const { return host; };
        char* GetMessage() const { return message; };
    private:
        char* host;
        char* message;
};

// Parser the messages returned by hosts
class Parser {
    public:
        Parser();
        ~Parser();
        void parse(char* host, char* message);
    private:
        FILE* cmdStdin;
};

// Read socket's and insert messages into a list
class Producer {
    public:
        Producer(list<char*> &messages, sem_t* s);
        ~Producer();
        void start();
    private:
        list<char*> msgs;
        SocketServer socket;
        sem_t* sem;
};

// Read messages from a list
class Consumer {
    public:
        Consumer(list<char*> &messages, sem_t* s);
        ~Consumer();
        void consume();
    private:
        list<char*> msgs;
        sem_t* sem;
        Parser p;
};

// Defining some useful types

typedef bool thread_quit_t;

// This type is passed to consumer thread
typedef struct consumer_thread_type {
    Consumer *c;
    list<char*> *messages;
    thread_quit_t quit;
    pthread_t thread_id;
} consumer_thread_t;

// This type is passed to producer thread
typedef struct producer_thread_type {
    list<char*> *messages;
    thread_quit_t quit;
    pthread_t thread_id;
} producer_thread_t;

#endif
