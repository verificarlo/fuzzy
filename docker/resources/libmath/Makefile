# Makefile for the instrumented shared library

.PHONY: tracer

all:
	cd standard && $(MAKE)
	cd quad && $(MAKE)
	cd mpfr && $(MAKE)

tracer:
	cd standard && $(MAKE) tracer
	cd quad && $(MAKE) tracer
	cd mpfr && $(MAKE) tracer

test: all
	cd tests && $(MAKE) test

perf: all
	cd tests && $(MAKE) perf

clean:
	cd standard && $(MAKE) clean
	cd quad && $(MAKE) clean
	cd mpfr && $(MAKE) clean

