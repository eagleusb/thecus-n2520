#
# Makefile for sensor chip drivers.
#


# APCI drivers

# Native drivers
# asb100, then w83781d go first, as they can override other drivers' addresses.
obj-$(CONFIG_THECUS_SENSORS_W83795)	+= w83795.o
obj-$(CONFIG_THECUS_SENSORS_F71882FG)	+= f71882fg.o
obj-$(CONFIG_THECUS_SENSORS_F75375S)	+= f75387sg.o
obj-$(CONFIG_THECUS_SENSORS_IT87)	+= it87.o
obj-$(CONFIG_THECUS_SENSORS_W83627EHF)	+= w83627ehf.o
obj-$(CONFIG_THECUS_SENSORS_TMP401)	+= tmp401.o

