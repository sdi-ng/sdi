SHELL:=/bin/bash
LDLIBS=-pthread
BIN=sdicore
BINSCLIENT=socketclient
CFLAGS=-DDEBUGFLAG
SRCDIR=.
OBJDIR=.

DEPSDIR = .deps
SOURCESXX=$(wildcard ./*.cpp)
DEPSXX = $(patsubst ${SRCDIR}/%.cpp,${DEPSDIR}/%.d,${SOURCESXX})
OBJECTSXX = $(patsubst ${SRCDIR}/%.cpp,${OBJDIR}/%.o,${SOURCESXX})

all: ${OBJECTSXX} sdicore socketclient

-include ${DEPSXX}

.deps/%.d:
	@mkdir -p $(dir $@)
	@touch $@

${OBJDIR}/%.o: ${SRCDIR}/%.cpp
	$(CXX) $(CFLAGS) -o $@ -c $< -MMD -MP -MF $(patsubst %.o,${DEPSDIR}/%.d,$@)

sdicore: sdicore.o socket.o producer.o consumer.o hostmessage.o parser.o
	$(CXX) -o $@ $^ $(CFLAGS) $(LDLIBS)

socketclient: socket.o socketclient.o
	$(CXX) -o $@ $^ $(CFLAGS) $(LDLIBS)

clean:
	rm -f *.o $(BIN) $(BINSCLIENT)

distclean: clean
