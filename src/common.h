#ifndef __COMMON_H
#define __COMMON_H

#define EVER ;;

// Print ERROR messages
#define ERROR(fmt,args...) (fflush(stderr), fprintf(stderr,fmt, \
                                               ##args), fflush(stderr) )

// Print WARNING messages
#define WARNING(fmt,args...) (fflush(stdout), printf(fmt, \
                                               ##args), fflush(stdout) )

// Print DEBUG messages, if DEBUGFLAG is "true"
#ifdef DEBUGFLAG
    #define DEBUG(fmt, args...) ( fflush(stdout), \
                                  printf("DEBUG: "fmt"", ##args), \
                                  fflush(stdout) )
#else
    #define DEBUG(fmt,args...)
#endif

#endif
