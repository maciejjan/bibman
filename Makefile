PREFIX=/usr
BIN_DIR=bin
MODULES_DIR=lib64/perl5/vendor_perl
MAN_DIR=share/man/man1

all: install

install:
	cp ./bibman $(PREFIX)/$(BIN_DIR)/
	cp -r ./Bibman $(PREFIX)/$(MODULES_DIR)/
	bibman --man | gzip > $(PREFIX)/$(MAN_DIR)/bibman.1.gz

uninstall:
	rm $(PREFIX)/$(BIN_DIR)/bibman
	rm -rf $(PREFIX)/$(MODULES_DIR)/Bibman
	rm -rf $(PREFIX)/$(MAN_DIR)/bibman.1.gz

