#include <iostream>
#include <stdio.h>
#include <semaphore.h>
#include "producer.h"
#include "common.h"
#include "hostmessage.h"

Producer::Producer(list<char*> &messages, sem_t s) {
    DEBUG("In Producer constructor\n");
    msgs = &messages;
    sem = s;
}

Producer::~Producer() {
    DEBUG("In Producer destructor\n");
    //TODO: destroy the socket
}

void Producer::start() {

    sem_wait(&sem);
    msgs->push_front(socket.GetMessage());
    sem_post(&sem);
}
