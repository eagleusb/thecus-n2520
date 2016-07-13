#!/bin/sh

##########################################################################
# Description from Realtek:
#     EEE is used to save power while traffic rate is low, to turn off it
#     won't affect other functions.
##########################################################################

OPT=$1

init_env(){
	APM_ENET="/sys/bus/of_platform/drivers/apm86xxx-enet"
	APM_MII_READ="${APM_ENET}/mii_read"
	APM_MII_WRITE="${APM_ENET}/mii_write"
}

# disable all EEE
eee_disable(){
	echo "apm86xxx-enet: Disable all EEE functions on PHY"
	echo 0 1 31 0x0000 > $APM_MII_WRITE 
	echo 0 1  0 0x8000 > $APM_MII_WRITE 

	echo 0 1 31 0x0005 > $APM_MII_WRITE 
	echo 0 1  5 0x8b85 > $APM_MII_WRITE 
	echo 0 1  6 0x0ae2 > $APM_MII_WRITE 
	echo 0 1 31 0x0007 > $APM_MII_WRITE 
	echo 0 1 30 0x0020 > $APM_MII_WRITE 
	echo 0 1 21 0x1008 > $APM_MII_WRITE 
	echo 0 1 31 0x0000 > $APM_MII_WRITE 
	echo 0 1 13 0x0007 > $APM_MII_WRITE 
	echo 0 1 14 0x003c > $APM_MII_WRITE 
	echo 0 1 13 0x4007 > $APM_MII_WRITE 
	echo 0 1 14 0x0000 > $APM_MII_WRITE
}

# Set PHY to disable power control of EEE to resolve D-link switch QM
# error issue.
phy_init(){
	echo "apm86xxx-enet: Setting MII"
	echo 0 1 31 0x0003 > $APM_MII_WRITE
	echo 0 1 25 0x3246 > $APM_MII_WRITE
	echo 0 1 16 0xa87c > $APM_MII_WRITE
	echo 0 1 31 0x0000 > $APM_MII_WRITE
	echo 0 1  0 0x1200 > $APM_MII_WRITE
}

init_env

case "$OPT" in
	init)
		[ -e "$APM_MII_WRITE" ] && phy_init
		;;
	eee)
		[ -e "$APM_MII_WRITE" ] && eee_disable
		;;
esac

# Wait for link ready
TIMEOUT=0
LINK_STS="`ethtool eth0 | awk -F ': ' '/Link detected:/ {print $2}'`"
while [ "$LINK_STS" != "yes" ];do
	[ "$TIMEOUT" -ge 15 ] && echo "wait link-up timeout!" && break
	echo "wait for link-up ..."
	sleep 1
	TIMEOUT=$((TIMEOUT+1))
	LINK_STS="`ethtool eth0 | awk -F ': ' '/Link detected:/ {print $2}'`"
done

exit 0
