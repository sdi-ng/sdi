#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include "common.h"
#include "parser.h"

void* parser_flush(void* ta) {
    DEBUG("p Entering parser_flush\n");
    p_flush_t *targ = (p_flush_t*) ta;
    while (!targ->quit) {
        DEBUG("p flushing cmdStdin\n");
        fflush(targ->cmdStdin);
        sleep(FLUSHPERIOD);
    }
    DEBUG("p Ending parser_flush\n");
}

Parser::Parser() {
    const char* cmd = "./parser.sh";

    DEBUG("In parser constructor\n");
    if ( !(cmdStdin = popen(cmd,"w")) ) {
        ERROR("Unable to create a Parser: %s\n",strerror(errno));
        exit(1);
    }
    thread.quit = false;
    thread.cmdStdin = cmdStdin;
    pthread_create(&(thread.tid),NULL,parser_flush,(void*)&thread);
}

Parser::~Parser() {

    DEBUG("In parser destructor\n");
    // Close parser.sh and cmdStdin stream
    if ( pclose(cmdStdin) != 0) {
        WARNING("parser.sh exit with error: %s\n",strerror(errno));
    }
    thread.quit = true;
    pthread_join(thread.tid,NULL);
}

void Parser::parse(char* host, char* message) {

    DEBUG("Parsing: %s: %s\n", host, message);
    fprintf(cmdStdin,"%s %s\n", host, message);
}
