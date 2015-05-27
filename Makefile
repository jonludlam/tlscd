BINDIR?=/usr/sbin
MANDIR?=/usr/share/man

.PHONY: install uninstall clean test

all: tlsc.native tlsc.1 tlsd.native tlsd.1

setup.ml: _oasis
	oasis setup

tlsc.native: setup.data version.ml src/tlsc.ml
	ocaml setup.ml -build

tlsd.native: setup.data version.ml src/tlsd.ml
	ocaml setup.ml -build

setup.data: setup.ml
	ocaml setup.ml -configure

version.ml: VERSION
	echo "let version = \"$(shell cat VERSION)\"" > version.ml

tlsc.1: tlsc.native
	./tlsc.native --help=groff > tlsc.1

tlsd.1: tlsd.native
	./tlsd.native --help=groff > tlsd.1

tlsd.pem: 
	openssl req -new -x509 -days 365 -nodes -out tlsd.pem -keyout tlsd.pem

install: tlsd.native tlsd.1 tlsc.native tlsc.1
	install -m 0755 tlsd.native ${BINDIR}/tlsd.native
	install -m 0755 tlsc.native ${BINDIR}/tlsc.native
	mkdir -p ${MANDIR}/man1
	install -m 0644 tlsc.1 ${MANDIR}/man1/tlsc.1
	install -m 0644 tlsd.1 ${MANDIR}/man1/tlsd.1

uninstall:
	rm -f ${BINDIR}/tlsc
	rm -f ${BINDIR}/tlsd
	rm -f ${MANDIR}/man1/tlsc.1
	rm -f ${MANDIR}/man1/tlsd.1

test:
	@echo No tests implemented yet

clean:
	rm -rf _build setup.data tlsc.1 tlsd.1 tlsc.native tlsd.native version.ml myocamlbuild.ml setup.log setup.ml
