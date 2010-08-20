#ifndef __CONSUMER_H_
#define __CONSUMER_H_

#include <iostream>
#include <list>
#include <semaphore.h>
#include "parser.h"

using namespace std;

// Read messages from a list
class Consumer {
    public:
        Consumer(list<string> &messages, sem_t &s, sem_t &se);
        ~Consumer();
        bool consume();
    private:
        list<string> *msgs;
        sem_t *sem;
        sem_t *sem_empty;
        Parser p;
        struct timespec ts; // Used to set a timeout on sem_wait()
};

#endif
