#include <iostream>
#include <stdio.h>
#include <semaphore.h>
#include "producer.h"
#include "common.h"
#include "hostmessage.h"

Producer::Producer(list<string> &messages, sem_t &s, sem_t &se) {
    DEBUG("In Producer constructor\n");
    msgs = &messages;
    sem = &s;
    sem_empty = &se;
}

Producer::~Producer() {
    DEBUG("In Producer destructor\n");
}

/* Write a message to msgs.
 * Return true if the message read is different from the quit tag
 * ("exit exit exit") and false otherwise */
bool Producer::start() {
    string msg(socket.GetMessage());

    sem_wait(sem);
    msgs->push_front(msg);
    sem_post(sem_empty);
    sem_post(sem);

    if (msg.find("exit exit exit") != string::npos) {
        return false;
    } else {
        return true;
    }
}
