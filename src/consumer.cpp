#include <iostream>
#include "common.h"
#include "hostmessage.h"
#include "consumer.h"

Consumer::Consumer(list<string> &messages, sem_t &s, sem_t &se) {
    DEBUG("In Consumer constructor\n");
    sem = &s;
    sem_empty = &se;
    msgs = &messages;
}

void Consumer::consume() {
    string message;

    sem_wait(sem_empty);
    sem_wait(sem);
    message = msgs->back();
    msgs->pop_back();
    sem_post(sem);

    HostMessage hm(message);
    p.parse(hm.GetHost(),hm.GetMessage());

}

Consumer::~Consumer() { }
