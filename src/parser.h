#ifndef __PARSER_H_
#define __PARSER_H_

#include <stdio.h>

// Parser the messages returned by hosts
class Parser {
    public:
        Parser();
        ~Parser();
        void parse(char* host, char* message);
    private:
        FILE* cmdStdin;
};

#endif
