#ifndef __PARSER_H_
#define __PARSER_H_

#include <stdio.h>

#define FLUSHPERIOD 30

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
        void parse(char* host, char* message);
    private:
        FILE* cmdStdin;
        p_flush_t thread;
};

#endif
