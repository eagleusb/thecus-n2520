#
# Generated Makefile - do not edit!
#
# Edit the Makefile in the project folder instead (../Makefile). Each target
# has a -pre and a -post target defined where you can add customized code.
#
# This makefile implements configuration specific macros and targets.


# Environment
MKDIR=mkdir
CP=cp
CCADMIN=CCadmin
RANLIB=ranlib
CC=gcc
CCC=g++
CXX=g++
FC=
AS=

# Macros
CND_PLATFORM=GNU-Linux-x86
CND_CONF=Release
CND_DISTDIR=dist

# Include project Makefile
include Makefile

# Object Directory
OBJECTDIR=build/${CND_CONF}/${CND_PLATFORM}

# Object Files
OBJECTFILES= \
	${OBJECTDIR}/timer.o \
	${OBJECTDIR}/cmd.o \
	${OBJECTDIR}/cmd_queue.o \
	${OBJECTDIR}/menu.o \
	${OBJECTDIR}/scr_template.o \
	${OBJECTDIR}/sqliteapi.o \
	${OBJECTDIR}/utility.o \
	${OBJECTDIR}/stringtable.o \
	${OBJECTDIR}/main.o \
	${OBJECTDIR}/sysinfo.o \
	${OBJECTDIR}/i2c.o

# C Compiler Flags
CFLAGS=

# CC Compiler Flags
CCFLAGS=
CXXFLAGS=

# Fortran Compiler Flags
FFLAGS=

# Assembler Flags
ASFLAGS=

# Link Libraries and Options
LDLIBSOPTIONS=-Wl,-rpath /usr/local/lib -lpthread -lsqlite3

# Build Targets
.build-conf: ${BUILD_SUBPROJECTS}
	${MAKE}  -f nbproject/Makefile-Release.mk dist/Release/GNU-Linux-x86/agent3

dist/Release/GNU-Linux-x86/agent3: ${OBJECTFILES}
	${MKDIR} -p dist/Release/GNU-Linux-x86
	${LINK.c} -o ${CND_DISTDIR}/${CND_CONF}/${CND_PLATFORM}/agent3 -s ${OBJECTFILES} ${LDLIBSOPTIONS} 

${OBJECTDIR}/timer.o: nbproject/Makefile-${CND_CONF}.mk timer.c 
	${MKDIR} -p ${OBJECTDIR}
	${RM} $@.d
	$(COMPILE.c) -O2 -MMD -MP -MF $@.d -o ${OBJECTDIR}/timer.o timer.c

${OBJECTDIR}/cmd.o: nbproject/Makefile-${CND_CONF}.mk cmd.c 
	${MKDIR} -p ${OBJECTDIR}
	${RM} $@.d
	$(COMPILE.c) -O2 -MMD -MP -MF $@.d -o ${OBJECTDIR}/cmd.o cmd.c

${OBJECTDIR}/cmd_queue.o: nbproject/Makefile-${CND_CONF}.mk cmd_queue.c 
	${MKDIR} -p ${OBJECTDIR}
	${RM} $@.d
	$(COMPILE.c) -O2 -MMD -MP -MF $@.d -o ${OBJECTDIR}/cmd_queue.o cmd_queue.c

${OBJECTDIR}/menu.o: nbproject/Makefile-${CND_CONF}.mk menu.c 
	${MKDIR} -p ${OBJECTDIR}
	${RM} $@.d
	$(COMPILE.c) -O2 -MMD -MP -MF $@.d -o ${OBJECTDIR}/menu.o menu.c

${OBJECTDIR}/scr_template.o: nbproject/Makefile-${CND_CONF}.mk scr_template.c 
	${MKDIR} -p ${OBJECTDIR}
	${RM} $@.d
	$(COMPILE.c) -O2 -MMD -MP -MF $@.d -o ${OBJECTDIR}/scr_template.o scr_template.c

${OBJECTDIR}/sqliteapi.o: nbproject/Makefile-${CND_CONF}.mk sqliteapi.c 
	${MKDIR} -p ${OBJECTDIR}
	${RM} $@.d
	$(COMPILE.c) -O2 -MMD -MP -MF $@.d -o ${OBJECTDIR}/sqliteapi.o sqliteapi.c

${OBJECTDIR}/utility.o: nbproject/Makefile-${CND_CONF}.mk utility.c 
	${MKDIR} -p ${OBJECTDIR}
	${RM} $@.d
	$(COMPILE.c) -O2 -MMD -MP -MF $@.d -o ${OBJECTDIR}/utility.o utility.c

${OBJECTDIR}/stringtable.o: nbproject/Makefile-${CND_CONF}.mk stringtable.c 
	${MKDIR} -p ${OBJECTDIR}
	${RM} $@.d
	$(COMPILE.c) -O2 -MMD -MP -MF $@.d -o ${OBJECTDIR}/stringtable.o stringtable.c

${OBJECTDIR}/main.o: nbproject/Makefile-${CND_CONF}.mk main.c 
	${MKDIR} -p ${OBJECTDIR}
	${RM} $@.d
	$(COMPILE.c) -O2 -MMD -MP -MF $@.d -o ${OBJECTDIR}/main.o main.c

${OBJECTDIR}/sysinfo.o: nbproject/Makefile-${CND_CONF}.mk sysinfo.c 
	${MKDIR} -p ${OBJECTDIR}
	${RM} $@.d
	$(COMPILE.c) -O2 -MMD -MP -MF $@.d -o ${OBJECTDIR}/sysinfo.o sysinfo.c

${OBJECTDIR}/i2c.o: nbproject/Makefile-${CND_CONF}.mk i2c.c 
	${MKDIR} -p ${OBJECTDIR}
	${RM} $@.d
	$(COMPILE.c) -O2 -MMD -MP -MF $@.d -o ${OBJECTDIR}/i2c.o i2c.c

# Subprojects
.build-subprojects:

# Clean Targets
.clean-conf:
	${RM} -r build/Release
	${RM} dist/Release/GNU-Linux-x86/agent3

# Subprojects
.clean-subprojects:

# Enable dependency checking
.dep.inc: .depcheck-impl

include .dep.inc
