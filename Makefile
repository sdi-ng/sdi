SFUSER:=none

default:
	@echo "ooops, run 'make sync' when you are sure of what you're doing"

sync: sync-sfuser sync-real
	@echo

sync-sfuser:
	@if test $(SFUSER) = "none"; then\
		echo "Missing SFUSER"; \
		exit 1; \
	fi

sync-real:
	@rsync -rlptDHx --progress --del . $(SFUSER),sdi@web.sf.net:htdocs
