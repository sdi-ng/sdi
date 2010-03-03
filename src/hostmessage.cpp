#include <iostream>
#include <stdlib.h>
#include <string>
#include <sstream>
#include "hostmessage.h"

HostMessage::HostMessage(string msg) {
    unsigned int idx = msg.find_first_of(" ",0);
    host = msg.substr(0,idx);
    message = msg.substr(idx+1);
}

HostMessage::~HostMessage() { }
