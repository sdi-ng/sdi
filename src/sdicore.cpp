#include <iostream>
#include <list>
#include <vector>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "sdicore.h"
#include "socket.h"
#include "common.h"

using namespace std;

// Globals
sem_t* sem_global; // Semaphore

// ------------------------------------------------------------------
// Implementation of Parser class
// ------------------------------------------------------------------
Parser::Parser() {
    const char* cmd = "parser.sh";

    DEBUG("In parser constructor\n");
    if ( !(cmdStdin = popen(cmd,"w")) ) {
        ERROR("Unable to create a Parser: %s\n",strerror(errno));
        exit(1);
    }
}

Parser::~Parser() {

    DEBUG("In parser destructor\n");
    // Close parser.sh and cmdStdin stream
    fprintf(cmdStdin,"exit exit exit\nexit exit exit\n",NULL);
    if ( pclose(cmdStdin) != 0) {
        WARNING("parser.sh exit with error: %s\n",strerror(errno));
    }
}

void Parser::parse(char* host, char* message) {

    DEBUG("Parsing: %s", message);
    fprintf(cmdStdin,"%s\n",message);
}

// ------------------------------------------------------------------
// Implementation of Producer class
// ------------------------------------------------------------------
Producer::Producer(list<char*> &messages, sem_t* s) {
    DEBUG("In Producer constructor\n");
    msgs = messages;
    sem = s;
    SocketServer socket;
}

Producer::~Producer() {
    DEBUG("In Producer constructor\n");
    //TODO: destroy the socket
}

void Producer::start() {

    sem_wait(sem);
    msgs.push_front(socket.GetMessage());
    sem_post(sem);
}

// ------------------------------------------------------------------
// Implementation of Consumer class
// ------------------------------------------------------------------
Consumer::Consumer(list<char*> &messages, sem_t* s) {
    DEBUG("In Consumer constructor\n");
    sem = s;
    msgs = messages;
    p = Parser();
}

void Consumer::consume() {
    char* message;

    sem_wait(sem);
    message = msgs.back();
    msgs.pop_back();
    sem_post(sem);

    HostMessage hm(message);
    p.parse(hm.GetHost(),hm.GetMessage());

}

Consumer::~Consumer() {
    delete &p;
}

// ------------------------------------------------------------------
// Implementation of HostMessage class
// ------------------------------------------------------------------
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

// This thread is reponsible to keep the consumer consuming
void* consumer_thread(void* threadarg) {
    consumer_thread_t* ct = (consumer_thread_t*) threadarg;
    Consumer c(*ct->messages,sem_global);
    while ( !ct->quit ) {
        c.consume();
    }
}

// This thread is reponsible to keep the producer producing
void* producer_thread(void* targ) {
    producer_thread_t* p = (producer_thread_t*) targ;
    Producer prod(*p->messages,sem_global);
    while ( !p->quit ) {
        prod.start();
    }
}

// TODO: substitute this function by a type which allows initialization
consumer_thread_t* init_consumer_thread(list<char*> &messages) {
    consumer_thread_t* ct;
    ct->quit = false;
    ct->messages = &messages;
    return ct;
}

// ------------------------------------------------------------------
// MAIN
// ------------------------------------------------------------------
int main(int argc, char** argv) {

    list<char*> messages;
    sem_init(sem_global, 0, 1);
    unsigned int threads_consumer_counter = 0;
    unsigned int i;
    consumer_thread_t* ct_tmp;
    vector<consumer_thread_t*> threads_consumer;
    producer_thread_t pt;

    // Initialize pt var.
    // TODO: Make possible to initialize in variable declaration
    pt.messages = &messages;
    pt.quit = false;

    // Create producer thread
    pthread_create(&pt.thread_id, NULL, producer_thread,(void *)&pt);

    // Create the first consumer thread
    ct_tmp = init_consumer_thread(messages);
    pthread_create(&(ct_tmp->thread_id), NULL, consumer_thread,
                        (void*)ct_tmp);
    threads_consumer.push_back(ct_tmp);

    for ( EVER ) {
        // TODO: Improve this "if" to a smart one
        // If the list gets large enough, create a new Consumer
        if ( messages.size() > 100 ) {
            ct_tmp = init_consumer_thread(messages);
            pthread_create(&(ct_tmp->thread_id), NULL, consumer_thread,
                                 (void*)ct_tmp);
            threads_consumer.push_back(ct_tmp);
        // If the list gets short again, destroy a Consumer
        } else if ( messages.size() < 100 && threads_consumer.size() > 1 ) {
            ct_tmp = threads_consumer.back();
            threads_consumer.pop_back();
            ct_tmp->quit = true;
            // TODO: Consumer can wait for ever for a message comming
            // from the socket. Create a way to ensure that this will never
            // happen, or the program will hold in this line
            pthread_join(ct_tmp->thread_id,NULL);
        }
    }

    pt.quit = true;
    pthread_join(pt.thread_id, NULL);
    for (i=0;i<threads_consumer.size();i++) {
        (threads_consumer[i])->quit = true;
        // TODO: Consumer can wait for ever for a message comming
        // from the socket. Create a way to ensure that this will never
        // happen, or the program will hold in this line
        pthread_join((threads_consumer[i])->thread_id, NULL);
    }
    sem_destroy(sem_global);
    return 0;
}
