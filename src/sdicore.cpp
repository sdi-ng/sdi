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
#include "producer.h"
#include "consumer.h"
#include "parser.h"

using namespace std;

// Globals
sem_t sem_global; // Semaphore
sem_t sem_empty; // Holds the execution when the messages list is empty

// This thread is reponsible to keep the consumer consuming
void* consumer_thread(void* threadarg) {
    consumer_thread_t* ct = (consumer_thread_t*) threadarg;
    Consumer c(*ct->messages,sem_global,sem_empty);
    while ( !ct->quit ) {
        c.consume();
    }
}

// This thread is reponsible to keep the producer producing
void* producer_thread(void* targ) {
    producer_thread_t* p = (producer_thread_t*) targ;
    Producer prod(*p->messages,sem_global,sem_empty);
    while ( !p->quit ) {
        prod.start();
    }
}

// TODO: substitute this function by a type which allows initialization
consumer_thread_t* init_consumer_thread(list<string> &messages) {
    consumer_thread_t* ct;
    ct = (consumer_thread_t*) malloc(sizeof(consumer_thread_t));
    ct->quit = false;
    ct->messages = &messages;
    return ct;
}

// ------------------------------------------------------------------
// MAIN
// ------------------------------------------------------------------
int main(int argc, char** argv) {

    list<string> messages;
    sem_init(&sem_global, 0, 1);
    sem_init(&sem_empty, 0, 0);
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
    sem_destroy(&sem_global);
    return 0;
}
