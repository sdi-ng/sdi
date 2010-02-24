SHELL:=/bin/bash
BIN=sdicore
BINSCLIENT=socketclient
SRCDIR=./src

all: $(BIN) $(BINSCLIENT)

$(BIN):
	@cd $(SRCDIR) && make $@
	mv ${SRCDIR}/${BIN} .

$(BINSCLIENT):
	@cd $(SRCDIR) && make $@
	mv ${SRCDIR}/${BINSCLIENT} .

clean:
	rm -f ${BIN} ${BINSCLIENT}

distclean: clean
	@cd ${SRCDIR} && make distclean
