PREFIX  ?= /usr/local

all:
	@echo nothing to build

install:
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	install -m 755 scripts/analizo-metrics-multi-project $(DESTDIR)$(PREFIX)/bin
	install -m 755 scripts/analizo-metrics-history       $(DESTDIR)$(PREFIX)/bin
	mkdir -p $(DESTDIR)$(PREFIX)/bin/metrics-history
	install -m 755 scripts/metrics-history/AnalizoRunner.rb          $(DESTDIR)$(PREFIX)/bin/metrics-history
	install -m 755 scripts/metrics-history/defs.rb                   $(DESTDIR)$(PREFIX)/bin/metrics-history
	install -m 755 scripts/metrics-history/Grit::Commit-extension.rb $(DESTDIR)$(PREFIX)/bin/metrics-history
	install -m 755 scripts/metrics-history/Log.rb                    $(DESTDIR)$(PREFIX)/bin/metrics-history
	install -m 755 scripts/metrics-history/Message.rb                $(DESTDIR)$(PREFIX)/bin/metrics-history
	install -m 755 scripts/metrics-history/Options.rb                $(DESTDIR)$(PREFIX)/bin/metrics-history
	install -m 755 scripts/metrics-history/VersionControl.rb         $(DESTDIR)$(PREFIX)/bin/metrics-history


uninstall:
	rm $(DESTDIR)$(PREFIX)/bin/analizo-metrics-multi-project
	rm $(DESTDIR)$(PREFIX)/bin/analizo-metrics-history
	rm $(DESTDIR)$(PREFIX)/bin/metrics-history/AnalizoRunner.rb
	rm $(DESTDIR)$(PREFIX)/bin/metrics-history/defs.rb
	rm $(DESTDIR)$(PREFIX)/bin/metrics-history/Grit::Commit-extension.rb
	rm $(DESTDIR)$(PREFIX)/bin/metrics-history/Log.rb
	rm $(DESTDIR)$(PREFIX)/bin/metrics-history/Message.rb
	rm $(DESTDIR)$(PREFIX)/bin/metrics-history/Options.rb
	rm $(DESTDIR)$(PREFIX)/bin/metrics-history/VersionControl.rb


clean:
	@echo nothing to clean
