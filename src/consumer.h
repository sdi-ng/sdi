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
        Consumer(list<char*> &messages, sem_t s, sem_t se);
        ~Consumer();
        void consume();
    private:
        list<char*> *msgs;
        sem_t sem;
        sem_t sem_empty;
        Parser p;
};

#endif
