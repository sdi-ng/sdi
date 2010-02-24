#ifndef __HOSTMESSAGE_H_
#define __HOSTMESSAGE_H_

// Separates msg into two elements: host and message
class HostMessage {
    public:
        HostMessage(char* msg);
        ~HostMessage();
        char* GetHost() const { return host; };
        char* GetMessage() const { return message; };
    private:
        char* host;
        char* message;
};

#endif
