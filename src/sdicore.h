#ifndef SDI_CORE_H
#define SDI_CORE_H

#include <list>
#include <string>
#include "consumer.h"

using namespace std;

#define MAXCONSUMER 100;

// Defining some useful types

typedef bool thread_quit_t;

// This type is passed to consumer thread
typedef struct consumer_thread_type {
    Consumer *c;
    list<string> *messages;
    thread_quit_t quit;
    pthread_t thread_id;
} consumer_thread_t;

// This type is passed to producer thread
typedef struct producer_thread_type {
    list<string> *messages;
    thread_quit_t quit;
    pthread_t thread_id;
} producer_thread_t;

#endif
