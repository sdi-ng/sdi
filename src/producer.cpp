#include <iostream>
#include <stdio.h>
#include <semaphore.h>
#include "producer.h"
#include "common.h"
#include "hostmessage.h"

Producer::Producer(list<char*> &messages, sem_t &s, sem_t &se) {
    DEBUG("In Producer constructor\n");
    msgs = &messages;
    sem = &s;
    sem_empty = &se;
}

Producer::~Producer() {
    DEBUG("In Producer destructor\n");
    //TODO: destroy the socket
}

void Producer::start() {

    char *msg = socket.GetMessage();

    sem_wait(sem);
    msgs->push_front(msg);
    sem_post(sem_empty);
    sem_post(sem);
}
