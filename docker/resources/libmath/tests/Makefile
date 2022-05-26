
.PHONY: test perf

test:
	python3 test.py --library=standard
	python3 test.py --library=quad
	python3 test.py --library=mpfr

perf: clean
	python3 test.py --library=ref --profiling 2> perf.ref.log
	python3 test.py --library=standard --profiling 2> perf.standard.log
	python3 test.py --library=quad --profiling 2> perf.quad.log
	python3 test.py --library=mpfr --profiling 2> perf.mpfr.log

clean:
	rm -f perf.*.log test 
