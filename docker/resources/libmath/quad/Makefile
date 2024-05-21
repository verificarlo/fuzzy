# Makefile for the instrumented shared library

INCLUDE_DIR = /usr/lib/gcc/x86_64-linux-gnu/7/include/
CC = verificarlo-c 
TRACER_FLAGS = --tracer --tracer-debug-mode --tracer-level=temporary
DEBUG_FLAGS = --save-temps --verbose -g
CFLAGS = -Wall -fPIC --verbose -I ${INCLUDE_DIR}  # C flags
LDFLAGS = -shared  # linking flags
LIBS= -ldl -lquadmath
RM = rm -f 

TARGET_LIB = libmath.so  # target lib

SRCS = src/wrapping_script.c  # source files
OBJS = $(SRCS:.c=.o)
ROOT = $(PWD)

.PHONY: tracer

$(TARGET_LIB): $(OBJS)
	$(CC) ${LDFLAGS} ${CFLAGS} ${LIBS} -o $@ $^

tracer:
	$(CC) ${TRACER_FLAGS} ${CFLAGS} ${LDFLAGS} ${LIBS} -o ${TARGET_LIB} $(SRCS)

clean:
	-${RM} ${TARGET_LIB} ${OBJS} $(SRCS:.c=.d) .vfcwrapper*

