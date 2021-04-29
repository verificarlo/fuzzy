#define _GNU_SOURCE
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef N
#define N 30
#endif

#ifndef REAL
#error "Type is not defined"
#endif

#ifndef FUNCTION
#error "Function to evaluate is not defined"
#endif

#define FMT(x) _Generic(x, float : "%.6a\n", double : "%.13a\n")
#define FMT2(x) _Generic(x, float : "%.6a %.6a\n", double : "%.13a %.13a\n")

#ifdef UNIVAR
void eval(char *argv[]) {
  REAL x = atof(argv[1]);
  for (int i = 0; i < N; i++) {
    REAL res = FUNCTION(x);
    printf(FMT(x), res);
  }
}
#endif
#ifdef BIVAR
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
  int *sign;
  for (int i = 0; i < N; i++) {
    REAL res = FUNCTION(x, sign);
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

  eval(argv);
  return 0;
}
