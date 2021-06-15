# Makefile for the instrumented shared library

CC = verificarlo-c --save-temps --verbose -g
TRACER_FLAGS = --tracer --tracer-debug-mode --tracer-level=temporary
CFLAGS = -fPIC --verbose  # C flags
LDFLAGS = -shared   # linking flags
LIBS= -ldl
RM = rm -f 

TARGET_LIB = libmath.so  # target lib

SRCS = src/wrapping_script.c  # source files
OBJS = $(SRCS:.c=.o)
ROOT = $(PWD)

.PHONY: tracer

$(TARGET_LIB): $(OBJS)
	$(CC) ${LDFLAGS} -ldl -o $@ $^

tracer:
	$(CC) ${TRACER_FLAGS} ${CFLAGS} ${LDFLAGS} ${LIBS} -o ${TARGET_LIB} $(SRCS)

test:
	cd tests && \
	./test.sh

clean:
	-${RM} ${TARGET_LIB} ${OBJS} $(SRCS:.c=.d)

