#ifndef __PARSER_H_
#define __PARSER_H_

#include <stdio.h>
#include <string>

#define FLUSHPERIOD 30

using namespace std;

typedef struct p_flush {
        FILE* cmdStdin;
        pthread_t tid;
        bool quit;
} p_flush_t;

// Parser the messages returned by hosts
class Parser {
    public:
        Parser();
        ~Parser();
        void parse(string host, string message);
    private:
        FILE* cmdStdin;
        p_flush_t thread;
};

#endif
