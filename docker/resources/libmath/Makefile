# Makefile for the instrumented shared library

.PHONY: tracer fast

all:
	cd fast && $(MAKE)
	cd standard && $(MAKE)
	cd quad && $(MAKE)
	cd mpfr && $(MAKE)

fast:
	cd fast && $(MAKE)

standard:
	cd standard && $(MAKE)

quad:
	cd quad && $(MAKE)

mpfr:
	cd mfpr && $(MAKE)


tracer:
	cd fast && $(MAKE) tracer
	cd standard && $(MAKE) tracer
	cd quad && $(MAKE) tracer
	cd mpfr && $(MAKE) tracer

test: all
	cd tests && $(MAKE) test

perf: all
	cd tests && $(MAKE) perf

clean:
	cd fast && $(MAKE) clean
	cd standard && $(MAKE) clean
	cd quad && $(MAKE) clean
	cd mpfr && $(MAKE) clean

