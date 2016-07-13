/* 
 * File:   sqliteapi.h
 * Author: dorianko
 *
 * Created on 2009年10月7日, 下午 7:03
 */

#ifndef _SQLITEAPI_H
#define	_SQLITEAPI_H

#ifdef	__cplusplus
extern "C" {
#endif

int32_t conf_db_delete(int8_t *key, int8_t *tab);
int32_t conf_db_insert(int8_t *key, int8_t *tab, int8_t *value);
int32_t conf_db_select(int8_t *key, int8_t *tab, int8_t *value);
int32_t conf_db_update(int8_t *key, int8_t *tab, int8_t *value);
int32_t general_db_select(int8_t *in_db, int8_t *key, int8_t *tab, char *value);

#ifdef	__cplusplus
}
#endif

#endif	/* _SQLITEAPI_H */

