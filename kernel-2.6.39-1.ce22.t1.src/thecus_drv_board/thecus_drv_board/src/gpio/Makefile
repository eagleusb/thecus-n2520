#
# Makefile for miscellaneous I2C chip drivers.
#
# Do not add new drivers to this directory! It is DEPRECATED.
#
# Device drivers are better grouped according to the functionality they
# implement rather than to the bus they are connected to. In particular:
# * Hardware monitoring chip drivers go to drivers/hwmon
# * RTC chip drivers go to drivers/rtc
# * I/O expander drivers go to drivers/gpio
#

obj-$(CONFIG_THECUS_BOARD)	+= thecus_board.o

obj-$(CONFIG_THECUS_PCA9532)	+= pca9532.o

obj-$(CONFIG_THECUS_PICUART_GPIO)  += picuart_gpio.o

obj-$(CONFIG_THECUS_PIC24)  += pic24.o

obj-$(CONFIG_THECUS_N16000_IO)	+= n16000_io.o
n16000_io-objs			:= n16000_gpio.o n16000_board.o

obj-$(CONFIG_THECUS_N8900_IO)	+= n8900_io.o
n8900_io-objs			:= n8900_gpio.o n8900_board.o

obj-$(CONFIG_THECUS_N2800_IO)	+= n2800_io.o
n2800_io-objs			:= n2800_gpio.o n2800_board.o

obj-$(CONFIG_THECUS_N7700PRO_IO)+= n7700pro_io.o
n7700pro_io-objs		:= n7700pro_gpio.o n7700pro_board.o

obj-$(CONFIG_THECUS_N2520_IO)	+= n2520_io.o
n2520_io-objs			:= n2520_board.o

obj-$(CONFIG_THECUS_N2310_IO)	+= n2310_io.o
n2310_io-objs			:= n2310_board.o
