#ifndef __PRODUCER_H_
#define __PRODUCER_H_

#include <list>
#include <semaphore.h>
#include "socket.h"

// Read socket's and insert messages into a list
class Producer {
    public:
        Producer(list<char*> &messages, sem_t &s, sem_t &se);
        ~Producer();
        void start();
    private:
        list<char*> *msgs;
        SocketServer socket;
        sem_t *sem;
        sem_t *sem_empty;
};

#endif
