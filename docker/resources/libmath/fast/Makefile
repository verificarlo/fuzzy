# Makefile for the instrumented shared library

CC = gcc 
TRACER_FLAGS = --tracer --tracer-debug-mode --tracer-level=temporary
DEBUG_FLAGS = --save-temps -g
CFLAGS = -Wall -fPIC  # C flags
LDFLAGS = -shared # linking flags
LIBS= -ldl
RM = rm -f 

TARGET_LIB = libmath.so  # target lib

SRCS = src/wrapping_script.c  # source files
OBJS = $(SRCS:.c=.o)
ROOT = $(PWD)


.PHONY: tracer

$(TARGET_LIB): $(OBJS)
	$(CC) ${LDFLAGS} ${CFLAGS} -o $@ $^ ${LIBS} 

tracer:
	$(CC) ${TRACER_FLAGS} ${CFLAGS} ${LDFLAGS} -o ${TARGET_LIB} $(SRCS) ${LIBS}

clean:
	-${RM} ${TARGET_LIB} ${OBJS} $(SRCS:.c=.d) .vfcwrapper*

