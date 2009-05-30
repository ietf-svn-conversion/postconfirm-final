CFLAGS=
OFLAGS=-pthread -fno-strict-aliasing -DNDEBUG -g -fwrapv -O2 -fPIC -I/usr/include/python2.5
WFLAGS=-Waggregate-return -Wall -Wcast-align -Wcast-qual -Wconversion -Werror -Wmissing-declarations -Wmissing-prototypes -Wnested-externs -Wpointer-arith -Wredundant-decls -Wstrict-prototypes -Wwrite-strings
SOFLAGS=-pthread -shared -Wl,-O1 -Wl,-Bsymbolic-functions 

CC=gcc

tool := postconfirmd

# The user that the postconfirmd daemon will run as
user := mail

prefix := /usr/local
shared := /usr/share

module := postconfirm

sources = *.py *.c postconfirmd.1 postconfirm.conf confirm.email.template postconfirm.init wrapper INSTALL

binaries = postconfirmc fdpass.so 

# ----------------------------------------------------------------------

include Makefile.common

% : %.c
	$(CC) $(CFLAGS) $(WFLAGS) -o $@ $(LDFLAGS) $<

%.o : %.c
	$(CC) $(OFLAGS) $(WFLAGS) -o $@ -c $<

%.so : %.o
	$(CC) $(SOFLAGS) -o $@ $(LDFLAGS) $<

install:: postconfirmc postconfirmd postconfirmd.py postconfirm.conf fdpass.so
	sudo install -o root    -d /etc/$(module) $(shared)/$(module)/
	sudo install -o $(user) -d /var/run/$(module) /var/cache/$(module) $prefix/sbin/
	#
	[ -f /etc/$(module)/postconfirm.conf ] || sudo install -o root postconfirm.conf /etc/$(module)/
	[ -f /etc/$(module)/confirm.email.template ] || sudo install -o root confirm.email.template /etc/$(module)/
	#
	if [ ! -f /etc/$(module)/hash.key ]; then head -c 128 /dev/urandom > hash.key; sudo install -o $(user) -m 600 hash.key /etc/$(module)/; rm hash.key; fi
	#
	sudo install -o root -T postconfirm.init /etc/init.d/postconfirmd
	sudo update-rc.d postconfirmd defaults 30 70
	sudo install -o root postconfirmc $(prefix)/bin/
	sudo install -o root *.py *.so wrapper $(shared)/$(module)/
	sudo python -c "import compileall; compileall.compile_dir('$(shared)/$(module)/');"
	sudo ln -sf $(shared)/$(module)/$(tool).py $(prefix)/sbin/$(tool)
	sudo ln -sf $(shared)/$(module)/wrapper $(shared)/$(module)/mailman
