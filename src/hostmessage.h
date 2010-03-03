#ifndef __HOSTMESSAGE_H_
#define __HOSTMESSAGE_H_

#include <string>

using namespace std;

// Separates msg into two elements: host and message
class HostMessage {
    public:
        HostMessage(string msg);
        ~HostMessage();
        string GetHost() const { return host; };
        string GetMessage() const { return message; };
    private:
        string host;
        string message;
};

#endif
