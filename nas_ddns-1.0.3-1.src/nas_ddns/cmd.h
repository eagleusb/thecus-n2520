#ifndef __CMD_H
#define __CMD_H

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


#define MAXBUFSIZE 1000

int min(int a, int b) {
	return ( (a<b)? a: b);
}

// This struct will be used to tranfer command and data from client to server
struct cmd_data {
	char cmd[1024];
	char data[1024];
};


// This function will retrieve data in PASCAL string format, i.e. length, then data.
void sock_to_buf(int sockfd, char* data) {
	int rb;		// read bytes each time
	int received;	// currently received bytes
	int len;	// totally expected data bytes
	int rest;	// the rest bytes not received yet
	uint32_t nlen;
	char buf[MAXBUFSIZE];

	// A PASCAL string type, length first, then data
	rb = recv(sockfd, &nlen, 4, 0 );	
	len = ntohl ( nlen );
	//printf ("Len = %d \n", len);	

	received = 0;
	rest = len;
	while ( rest > 0 ) {
		rb = recv(sockfd, buf, min(MAXBUFSIZE, rest), 0 );	
		buf[rb] = '\0';
		//printf ("buf =[%s]\n", buf);	
		strncpy((char*) data+received, buf, rb);
		rest -= rb;
		received += rb;
	}
	return ;
}

long get_filesize(char* path){
	struct stat statbuf;
	if ( stat(path, &statbuf) == -1 ){
		printf("Unable to get %s's size!\n", path);
		return ( -1 );
	}
	return (statbuf.st_size);
}

void sock_to_file(int sockfd, char* filename){
	int fd;
	int len, rb, rest;
	uint32_t nlen;
	char buf[MAXBUFSIZE];

	// Get the file size first
	recv(sockfd, &nlen, sizeof(uint32_t), 0);
	len=ntohl(nlen);
	//printf("file size is %d\n", len);	
	
	fd = open(filename, O_RDWR|O_APPEND|O_CREAT, 0666);
	if ( fd < 0 ){
		printf("filed to open %s for writting!\n", filename);
		return;
	}
	rest = len;
	while ( rest > 0 ){
		rb = recv(sockfd, buf, min(MAXBUFSIZE, rest), 0);
		buf[rb] = '\0';	
		//printf("client buf=[%s]\n", buf);
		write(fd, buf, rb);
		rest -= rb;
	}	

	close(fd);
	return;
}

void file_to_sock(int sockfd, char* filename){
	int fd;
	int len, rb, rest;
	uint32_t nlen;
	char buf[MAXBUFSIZE];

	// Get the file size first, and inform to peer first
	len = get_filesize(filename);
	nlen = htonl( len );
	rb = send(sockfd, &nlen, 4, 0);
	//printf("file size=%d\n", len);

	// Now, start to sending data	
	fd = open(filename, O_RDONLY);
	rest = len;
	while ( (rb = read(fd, buf, rest)) > 0  ){
		buf[rb] = '\0';
		//printf("buf=[%s]\n", buf);
		rb = send(sockfd, buf, min(MAXBUFSIZE, rest), 0);
		rest -= rb;
	}	

	close(fd);
	return;
}

#endif
