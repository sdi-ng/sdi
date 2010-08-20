#ifndef __PRODUCER_H_
#define __PRODUCER_H_

#include <list>
#include <semaphore.h>
#include "socket.h"

// Read socket's and insert messages into a list
class Producer {
    public:
        Producer(list<string> &messages, sem_t &s, sem_t &se);
        ~Producer();
        bool start();
    private:
        list<string> *msgs;
        SocketServer socket;
        sem_t *sem;
        sem_t *sem_empty;
};

#endif
