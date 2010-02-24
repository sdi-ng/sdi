#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include "common.h"
#include "parser.h"

Parser::Parser() {
    const char* cmd = "./parser.sh";

    DEBUG("In parser constructor\n");
    if ( !(cmdStdin = popen(cmd,"w")) ) {
        ERROR("Unable to create a Parser: %s\n",strerror(errno));
        exit(1);
    }
}

Parser::~Parser() {

    DEBUG("In parser destructor\n");
    // Close parser.sh and cmdStdin stream
    if ( pclose(cmdStdin) != 0) {
        WARNING("parser.sh exit with error: %s\n",strerror(errno));
    }
}

void Parser::parse(char* host, char* message) {

    DEBUG("Parsing: %s", message);
    fprintf(cmdStdin,"%s\n",message);
}
