CC = gcc
CFLAGS = -g -Wall -O2

#LOPTS = -L. -lnettool -lsqlite3 -DUDPRDBG 
#LOPTS = -L. -lnettool -lsqlite3

all: verify

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# verify.cgi
verify_cgi_OBJS = verify.o lib.o ../common.o ../sem.o ../md5.o
verify: $(verify_cgi_OBJS) 
	$(CC) $(verify_cgi_OBJS) -o verify.cgi -L/usr/lib/mysql -lmysqlclient

# clean
clean:
	rm -f *.o verify.cgi 






