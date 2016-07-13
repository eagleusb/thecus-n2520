#ifndef _LIB_H
#define _LIB_H

#include <stdio.h>

#define HTML(x...)	fprintf(stdout, x)

typedef struct {
    char *name;
    char *value;
    int pos;
} QryData;

extern QryData *Value;

void GUIFreeQryData(QryData * data);
char *GUIGetQueryString(char *datastring);
char *GUIGetPostString(char *datastring);
int GUIValSecNo(char *datastring, char delim);
void GUIChopQryData(char *datastring, int total);
char *GUIGetValue(char *name, int count);
void cgiHeaderContentType(char *mimeType);

#endif				/* _LIB_H */
