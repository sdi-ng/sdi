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

/* Get a message from msgs and send it to parser.
 * Return true if a regular message was read and false if received a tag
 * ("exit exit exit") to quit. */
bool Consumer::consume() {
    string message;
    bool read = true;

    sem_wait(sem_empty);
    sem_wait(sem);
    message = msgs->back();
    msgs->pop_back();
    sem_post(sem);

    HostMessage hm(message);

    if (hm.GetMessage().find("exit exit exit") != string::npos) {
        read = false;
    }

    p.parse(hm.GetHost(),hm.GetMessage());

    return read;
}

Consumer::~Consumer() { }
