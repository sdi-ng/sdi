#include <iostream>
#include "common.h"
#include "hostmessage.h"
#include "consumer.h"

Consumer::Consumer(list<char*> &messages, sem_t s) {
    DEBUG("In Consumer constructor\n");
    sem = s;
    msgs = messages;
    p = Parser();
}

void Consumer::consume() {
    char* message;

    sem_wait(&sem);
    message = msgs.back();
    msgs.pop_back();
    sem_post(&sem);

    HostMessage hm(message);
    p.parse(hm.GetHost(),hm.GetMessage());

}

Consumer::~Consumer() {
    delete &p;
}
