#include <iostream>
#include <time.h>
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

    // Workaround to avoid an infinite block of consumer thread
    clock_gettime(CLOCK_REALTIME, &ts);
    ts.tv_sec += 10;

    if (sem_timedwait(sem_empty, &ts) == -1) {
        return read;
    }

    if (sem_timedwait(sem, &ts) == -1) {
        return read;
    }

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
