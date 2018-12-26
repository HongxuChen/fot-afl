#
# american fuzzy lop - makefile
# -----------------------------
#
# Written and maintained by Michal Zalewski <lcamtuf@google.com>
# 
# Copyright 2013, 2014, 2015, 2016 Google Inc. All rights reserved.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# 
#   http://www.apache.org/licenses/LICENSE-2.0
#

PROGNAME    = fafl
VERSION     = $(shell grep '^\#define VERSION ' config.h | cut -d '"' -f2)

PREFIX     ?= /usr/local
BIN_PATH    = $(PREFIX)/bin
HELPER_PATH = $(PREFIX)/lib/fafl
DOC_PATH    = $(PREFIX)/share/doc/fafl
MISC_PATH   = $(PREFIX)/share/fafl

# PROGS intentionally omit fafl-as, which gets installed elsewhere.

PROGS       = fafl-gcc fafl-fuzz fafl-showmap fafl-tmin fafl-gotcpu fafl-analyze
SH_PROGS    = fafl-plot fafl-cmin fafl-whatsup

CFLAGS     ?= -O3 -funroll-loops
CFLAGS     += -Wall -D_FORTIFY_SOURCE=2 -g -Wno-pointer-sign \
	      -DFOT_PATH=\"$(HELPER_PATH)\" -DDOC_PATH=\"$(DOC_PATH)\" \
	      -DBIN_PATH=\"$(BIN_PATH)\"

ifneq "$(filter Linux GNU%,$(shell uname))" ""
  LDFLAGS  += -ldl -lm
endif

ifeq "$(findstring clang, $(shell $(CC) --version 2>/dev/null))" ""
  TEST_CC   = fafl-gcc
else
  TEST_CC   = fafl-clang
endif

COMM_HDR    = alloc-inl.h config.h debug.h types.h

all: test_x86 $(PROGS) fafl-as test_build all_done

ifndef FOT_NO_X86

test_x86:
	@echo "[*] Checking for the ability to compile x86 code..."
	@echo 'main() { __asm__("xorb %al, %al"); }' | $(CC) -w -x c - -o .test || ( echo; echo "Oops, looks like your compiler can't generate x86 code."; echo; echo "Don't panic! You can use the LLVM or QEMU mode, but see docs/INSTALL first."; echo "(To ignore this error, set FOT_NO_X86=1 and try again.)"; echo; exit 1 )
	@rm -f .test
	@echo "[+] Everything seems to be working, ready to compile."

else

test_x86:
	@echo "[!] Note: skipping x86 compilation checks (FOT_NO_X86 set)."

endif

fafl-gcc: fafl-gcc.c $(COMM_HDR) | test_x86
	$(CC) $(CFLAGS) $@.c -o $@ $(LDFLAGS)
	set -e; for i in fafl-g++ fafl-clang fafl-clang++; do ln -sf fafl-gcc $$i; done

fafl-as: fafl-as.c fafl-as.h $(COMM_HDR) | test_x86
	$(CC) $(CFLAGS) $@.c -o $@ $(LDFLAGS)
	ln -sf fafl-as as

fafl-fuzz: fafl-fuzz.c $(COMM_HDR) | test_x86
	$(CC) $(CFLAGS) $@.c -o $@ $(LDFLAGS)

fafl-showmap: fafl-showmap.c $(COMM_HDR) | test_x86
	$(CC) $(CFLAGS) $@.c -o $@ $(LDFLAGS)

fafl-tmin: fafl-tmin.c $(COMM_HDR) | test_x86
	$(CC) $(CFLAGS) $@.c -o $@ $(LDFLAGS)

fafl-analyze: fafl-analyze.c $(COMM_HDR) | test_x86
	$(CC) $(CFLAGS) $@.c -o $@ $(LDFLAGS)

fafl-gotcpu: fafl-gotcpu.c $(COMM_HDR) | test_x86
	$(CC) $(CFLAGS) $@.c -o $@ $(LDFLAGS)

ifndef FOT_NO_X86

test_build: fafl-gcc fafl-as fafl-showmap
	@echo "[*] Testing the CC wrapper and instrumentation output..."
	unset FOT_USE_ASAN FOT_USE_MSAN; FOT_QUIET=1 FOT_INST_RATIO=100 FOT_PATH=. ./$(TEST_CC) $(CFLAGS) test-instr.c -o test-instr $(LDFLAGS)
	echo 0 | ./fafl-showmap -m none -q -o .test-instr0 ./test-instr
	echo 1 | ./fafl-showmap -m none -q -o .test-instr1 ./test-instr
	@rm -f test-instr
	@cmp -s .test-instr0 .test-instr1; DR="$$?"; rm -f .test-instr0 .test-instr1; if [ "$$DR" = "0" ]; then echo; echo "Oops, the instrumentation does not seem to be behaving correctly!"; echo; echo "Please ping <lcamtuf@google.com> to troubleshoot the issue."; echo; exit 1; fi
	@echo "[+] All right, the instrumentation seems to be working!"

else

test_build: fafl-gcc fafl-as fafl-showmap
	@echo "[!] Note: skipping build tests (you may need to use LLVM or QEMU mode)."

endif

all_done: test_build
	@if [ ! "`which clang 2>/dev/null`" = "" ]; then echo "[+] LLVM users: see llvm_mode/README.llvm for a faster alternative to fafl-gcc."; fi
	@echo "[+] All done! Be sure to review README - it's pretty short and useful."
	@if [ "`uname`" = "Darwin" ]; then printf "\nWARNING: Fuzzing on MacOS X is slow because of the unusually high overhead of\nfork() on this OS. Consider using Linux or *BSD. You can also use VirtualBox\n(virtualbox.org) to put FOT inside a Linux or *BSD VM.\n\n"; fi
	@! tty <&1 >/dev/null || printf "\033[0;30mNOTE: If you can read this, your terminal probably uses white background.\nThis will make the UI hard to read. See docs/status_screen.txt for advice.\033[0m\n" 2>/dev/null

.NOTPARALLEL: clean

clean:
	rm -f $(PROGS) fafl-as as fafl-g++ fafl-clang fafl-clang++ *.o *~ a.out core core.[1-9][0-9]* *.stackdump test .test test-instr .test-instr0 .test-instr1 qemu_mode/qemu-2.3.0.tar.bz2 fafl-qemu-trace
	rm -rf out_dir qemu_mode/qemu-2.3.0
	$(MAKE) -C llvm_mode clean
	$(MAKE) -C libdislocator clean
	$(MAKE) -C libtokencap clean

install: all
	mkdir -p -m 755 $${DESTDIR}$(BIN_PATH) $${DESTDIR}$(HELPER_PATH) $${DESTDIR}$(DOC_PATH) $${DESTDIR}$(MISC_PATH)
	rm -f $${DESTDIR}$(BIN_PATH)/fafl-plot.sh
	install -m 755 $(PROGS) $(SH_PROGS) $${DESTDIR}$(BIN_PATH)
	rm -f $${DESTDIR}$(BIN_PATH)/fafl-as
	if [ -f fafl-qemu-trace ]; then install -m 755 fafl-qemu-trace $${DESTDIR}$(BIN_PATH); fi
ifndef FOT_TRACE_PC
	if [ -f fafl-clang-fast -a -f fafl-llvm-pass.so -a -f fafl-llvm-rt.o ]; then set -e; install -m 755 fafl-clang-fast $${DESTDIR}$(BIN_PATH); ln -sf fafl-clang-fast $${DESTDIR}$(BIN_PATH)/fafl-clang-fast++; install -m 755 fafl-llvm-pass.so fafl-llvm-rt.o $${DESTDIR}$(HELPER_PATH); fi
else
	if [ -f fafl-clang-fast -a -f fafl-llvm-rt.o ]; then set -e; install -m 755 fafl-clang-fast $${DESTDIR}$(BIN_PATH); ln -sf fafl-clang-fast $${DESTDIR}$(BIN_PATH)/fafl-clang-fast++; install -m 755 fafl-llvm-rt.o $${DESTDIR}$(HELPER_PATH); fi
endif
	if [ -f fafl-llvm-rt-32.o ]; then set -e; install -m 755 fafl-llvm-rt-32.o $${DESTDIR}$(HELPER_PATH); fi
	if [ -f fafl-llvm-rt-64.o ]; then set -e; install -m 755 fafl-llvm-rt-64.o $${DESTDIR}$(HELPER_PATH); fi
	set -e; for i in fafl-g++ fafl-clang fafl-clang++; do ln -sf fafl-gcc $${DESTDIR}$(BIN_PATH)/$$i; done
	install -m 755 fafl-as $${DESTDIR}$(HELPER_PATH)
	ln -sf fafl-as $${DESTDIR}$(HELPER_PATH)/as
	install -m 644 docs/README docs/ChangeLog docs/*.txt $${DESTDIR}$(DOC_PATH)
	cp -r testcases/ $${DESTDIR}$(MISC_PATH)
	cp -r dictionaries/ $${DESTDIR}$(MISC_PATH)

publish: clean
	test "`basename $$PWD`" = "fafl" || exit 1
	test -f ~/www/fafl/releases/$(PROGNAME)-$(VERSION).tgz; if [ "$$?" = "0" ]; then echo; echo "Change program version in config.h, mmkay?"; echo; exit 1; fi
	cd ..; rm -rf $(PROGNAME)-$(VERSION); cp -pr $(PROGNAME) $(PROGNAME)-$(VERSION); \
	  tar -cvz -f ~/www/fafl/releases/$(PROGNAME)-$(VERSION).tgz $(PROGNAME)-$(VERSION)
	chmod 644 ~/www/fafl/releases/$(PROGNAME)-$(VERSION).tgz
	( cd ~/www/fafl/releases/; ln -s -f $(PROGNAME)-$(VERSION).tgz $(PROGNAME)-latest.tgz )
	cat docs/README >~/www/fafl/README.txt
	cat docs/status_screen.txt >~/www/fafl/status_screen.txt
	cat docs/historical_notes.txt >~/www/fafl/historical_notes.txt
	cat docs/technical_details.txt >~/www/fafl/technical_details.txt
	cat docs/ChangeLog >~/www/fafl/ChangeLog.txt
	cat docs/QuickStartGuide.txt >~/www/fafl/QuickStartGuide.txt
	echo -n "$(VERSION)" >~/www/fafl/version.txt
