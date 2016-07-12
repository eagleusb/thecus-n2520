#ifndef CMD_QUEUE_H_
#define CMD_QUEUE_H_

#ifdef	__cplusplus
extern "C" {
#endif

int32_t cmd_queue_add(uint8_t in_out, void *pData);
int32_t cmd_queue_get(uint8_t *pin_out, void **ppData);
int32_t cmd_queue_release(void);
void cmd_queue_handler(int32_t signum);

#ifdef	__cplusplus
}
#endif

#endif /*CMD_QUEUE_H_*/
