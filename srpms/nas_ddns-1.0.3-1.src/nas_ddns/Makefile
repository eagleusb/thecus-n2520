CC = gcc
CFLAGS = -g -Wall -O2

#LOPTS = -L. -lnettool -lsqlite3 -DUDPRDBG 
#LOPTS = -L. -lnettool -lsqlite3
SUBDIRS= cgi

all: ddns_client ddns_server clean_garbage write_loop
	@for dir in $(SUBDIRS); do \
	    cd $$dir && make; cd -; \
	done

%.o: %.c
	$(CC) $(CFLAGS) $(COPTS) -c $< -o $@

# client
CLIENT_OBJS = client.o md5.o packet.o common.o
ddns_client: $(CLIENT_OBJS)
	$(CC) $(CLIENT_OBJS) -o ddns_client -lcrypto

# server
SERVER_OBJS = server.o md5.o db.o packet.o common.o sem.o
ddns_server: $(SERVER_OBJS)
	$(CC) $(SERVER_OBJS) -o ddns_server -L/usr/lib/mysql -lmysqlclient -lcrypto

# clean_garbage
clean_garbage_OBJS = clean_garbage.o common.o sem.o
clean_garbage: $(clean_garbage_OBJS)
	$(CC) $(clean_garbage_OBJS) -o clean_garbage -L/usr/lib/mysql -lmysqlclient

# write_loop 
write_loop_OBJS = write_loop.o common.o sem.o
write_loop: $(write_loop_OBJS)
	$(CC) $(write_loop_OBJS) -o write_loop -L/usr/lib/mysql -lmysqlclient 


# clean
clean:
	rm -f *.o ddns_client ddns_server clean_garbage write_loop
	@for dir in $(SUBDIRS); do \
	    cd $$dir && make clean; cd -; \
	done
