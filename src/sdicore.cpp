#include <iostream>
#include <list>
#include <vector>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
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

bool program_quit = false; // Signals when the program needs to quit

// This function handle signals, sinalizing sdicore to quit
void signal_handler(int sig) {
    DEBUG("Closing sdicore\n");
    program_quit = true;
}

// This thread is reponsible to keep the consumer consuming
void* consumer_thread(void* threadarg) {
    consumer_thread_t* ct = (consumer_thread_t*) threadarg;
    Consumer c(*ct->messages,sem_global,sem_empty);
    while ( !ct->quit && c.consume());
    return NULL;
}

// This thread is reponsible to keep the producer producing
void* producer_thread(void* targ) {
    producer_thread_t* p = (producer_thread_t*) targ;
    Producer prod(*p->messages,sem_global,sem_empty);
    while ( !p->quit && prod.start());
    return NULL;
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

    signal(SIGINT,signal_handler);
    signal(SIGTERM,signal_handler);
    signal(SIGABRT,signal_handler);
    signal(SIGUSR1,signal_handler);

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

    while (!program_quit) {
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
            pthread_join(ct_tmp->thread_id,NULL);
        }
        // sleep 0.1 seconds
        usleep(100000);
    }
    // Sinalize to producer quit
    pt.quit = true;
    pthread_join(pt.thread_id, NULL);
    // Sinalize to consumers quit
    // This X is needed to keep the standard format of messages
    for (i=0;i<threads_consumer.size();i++)
        messages.push_back("X exit exit exit");
    for (i=0;i<threads_consumer.size();i++) {
        (threads_consumer[i])->quit = true;
        pthread_join((threads_consumer[i])->thread_id, NULL);
    }
    sem_destroy(&sem_global);
    sem_destroy(&sem_empty);
    return 0;
}
