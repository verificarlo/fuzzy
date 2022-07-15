#define _GNU_SOURCE
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef N
#define N 100
#endif

#define xstr(X) str(X)
#define str(X) #X

#ifndef REAL
#error "Type is not defined"
#endif

#ifndef FUNCTION
#error "Function to evaluate is not defined"
#endif

#ifdef PROFILING
#ifdef __i386
extern __inline__ uint64_t rdtsc(void) {
  uint64_t x;
  __asm__ volatile("rdtsc" : "=A"(x));
  return x;
}
#elif defined __amd64
extern __inline__ uint64_t rdtsc(void) {
  uint64_t a, d;
  __asm__ volatile("rdtsc" : "=a"(a), "=d"(d));
  return (d << 32) | a;
}
#define TIME(X)                                                                \
  uint64_t start = rdtsc();                                                    \
  X;                                                                           \
  uint64_t end = rdtsc();                                                      \
  fprintf(stderr, xstr(FUNCTION) " %ld\n", end - start);
#endif
#else
#define TIME(X) X;
#endif

#define FMT(x) _Generic(x, float : "%.6a\n", double : "%.13a\n")
#define FMT2(x) _Generic(x, float : "%.6a %.6a\n", double : "%.13a %.13a\n")

#ifdef UNIVARIATE
void eval(char *argv[]) {
  REAL x = atof(argv[1]);
  for (int i = 0; i < N; i++) {
    REAL res = FUNCTION(x);
    printf(FMT(x), res);
  }
}
#endif
#ifdef BIVARIATE
void eval(char *argv[]) {
  REAL x = atof(argv[1]);
  REAL y = atof(argv[2]);
  for (int i = 0; i < N; i++) {
    REAL res = FUNCTION(x, y);
    printf(FMT(x), res);
  }
}
#endif
#ifdef LGAMMA_R
void eval(char *argv[]) {
  REAL x = atof(argv[1]);
  int sign;
  for (int i = 0; i < N; i++) {
    REAL res = FUNCTION(x, &sign);
    printf(FMT(x), res);
  }
}
#endif
#ifdef SINCOS
void eval(char *argv[]) {
  REAL x = atof(argv[1]);
  REAL cosx, sinx;
  for (int i = 0; i < N; i++) {
    FUNCTION(x, &cosx, &sinx);
    printf(FMT2(x), cosx, sinx);
  }
}
#endif

int main(int argc, char *argv[]) {

  TIME(eval(argv));
  return 0;
}
