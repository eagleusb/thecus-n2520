#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "lib.h"
#include "../common.h"

QryData *Value;

void cgiHeaderContentType(char *mimeType)
{
    fprintf(stdout, "Content-type: %s\r\n\r\n", mimeType);
}

/**
 * Retrieve the QueryString from environment variables and convert the encoded characters.
 **/
char *GUIGetQueryString(char *datastring)
{
	if (getenv("QUERY_STRING") == NULL) {
		datastring = strdup("");
	} else {
		datastring = strdup(getenv("QUERY_STRING"));
	}

	return datastring;
}

/**
 * Retrieve the PostData from stdin and convert the encoded characters.
 **/
char *GUIGetPostString(char *datastring)
{
    int length, index, CharData;

    length = atoi(getenv("CONTENT_LENGTH"));
    datastring = (char *) malloc(length * 4);
    index = 0;

    while (index < length) {
	CharData = fgetc(stdin);
	if (CharData == EOF)
	    break;
	datastring[index] = CharData;
	index++;
    }

    datastring[index] = 0;

    return datastring;
}

/**
 * Convert the encoded characters.
 **/
char *GUIDataConv(char *str)
{
    char *strtemp = "";
    int length, loop, i = 0;

    length = strlen(str);
    strtemp = (char *) malloc(length + 1);

    for (loop = 0; loop < length; loop++, i++) {
	if (str[loop] == '+')
	    strtemp[i] = ' ';
	else if (str[loop] == '%') {
	    strtemp[i] =
		(toupper(str[loop + 1]) >=
		 'A' ? (toupper(str[loop + 1]) -
			55) * 16 : (toupper(str[loop + 1]) - 48) * 16) +
		(toupper(str[loop + 2]) >=
		 'A' ? (toupper(str[loop + 2]) -
			55) : (toupper(str[loop + 2]) - 48));
	    loop += 2;
	} else {
	    strtemp[i] = str[loop];
	}
    }

    strtemp[i] = 0;
    bzero(str, strlen(str));
    strcpy(str, strtemp);
    if (strtemp)
	free(strtemp);

    return str;
}

/**
 * Chop Query String to name=value pair structure.
 **/
void GUIChopQryData(char *datastring, int total)
{
    int length, index, start, ValIndex, i;
    char *temp;

    length = strlen(datastring) + 1;
    temp = (char *) malloc(length);
    memset(temp, 0, length);
    ValIndex = 0;
    start = 0;

    if (total == 0) {
	Value = NULL;
	if (temp)
	    free(temp);
	return;
    }


    for (i = 0; i < total; i++) {
	Value[i].name = NULL;
	Value[i].value = NULL;
	Value[i].pos = -2;
    }

    for (index = 0; index < length; index++) {
	if ((index == 0) || (datastring[index] == '=')
	    || (datastring[index] == '&') || (index == (length - 1))) {
	    if (datastring[index] == '=') {
		if (temp == NULL)
		    Value[ValIndex].name = strdup("");
		else
		    Value[ValIndex].name = strdup(temp);
	    } else if (datastring[index] == '&') {
		if (temp == NULL)
		    Value[ValIndex].value = strdup("");
		else
		    Value[ValIndex].value = strdup(GUIDataConv(temp));
		Value[ValIndex].pos = ValIndex;
		ValIndex++;
	    } else if (index == (length - 1)) {
		if (temp == NULL)
		    Value[ValIndex].value = strdup("");
		else
		    Value[ValIndex].value = strdup(GUIDataConv(temp));
		Value[ValIndex].pos = -1;
	    }
	    memset(temp, 0, strlen(temp));
	    start = 0;
	}
	if (datastring[index] != '=' && datastring[index] != '&') {
	    temp[start++] = datastring[index];
	}
    }

    if (temp)
	free(temp);
}

/**
 * Get value from Value array when giving name and count.
 **/
char *GUIGetValue(char *name, int count)
{
    int index = 0, c = 0;

    if ((Value == NULL) || (Value[0].name == NULL))
	return "";

    while (Value[index].pos >= -1) {
	if (Value[index].name && !strcmp(Value[index].name, name)) {
	    if ((c + 1) == count)
		return Value[index].value;
	    else
		c++;
	}

	if (Value[index].pos == (-1))
	    return "";

	index++;
    }

    return "";
}

/**
 * Count the number of variables separated by delim.
 **/
int GUIValSecNo(char *datastring, char delim)
{
    int length, index, total = 0;

    if ((length = strlen(datastring)) == 0)
	return total;

    for (index = 0; index < length; index++)
	if (datastring[index] == delim)
	    total++;
    total++;

    return total;
}

/**
 * Free QryData struct pointer.
 **/
void GUIFreeQryData(QryData * data)
{
    int i = 0;

    if (data == NULL)
	return;

    while (data[i].pos >= -1) {
	SAFE_FREE(data[i].name);
	SAFE_FREE(data[i].value);
	if (data[i].pos == -1) {
	    SAFE_FREE(data);
	    return;
	}
	i++;
    }

    return;
}
