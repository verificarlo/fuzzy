// test_libm <32|64>: print a few libm results as hexadecimal floats, in
// binary32 or binary64. The inputs are volatile so that the compiler does not
// evaluate the calls itself.
#define _GNU_SOURCE
#include <math.h>
#include <stdio.h>
#include <string.h>

static volatile double xs[] = {0.1, 0.5, 1.5, 3.0, 10.25};

int main(int argc, char **argv) {
  int binary32 = argc > 1 && strcmp(argv[1], "32") == 0;
  for (int i = 0; i < 5; i++) {
    double x = xs[i];
    if (binary32) {
      float f = (float)x, s, c;
      sincosf(f, &s, &c);
      printf("%a %a %a %a %a %a %a %a %a %a %a\n", sinf(f), expf(f), logf(f),
             powf(f, 1.25f), s, c, tanf(f), sinhf(f), coshf(f), tanhf(f),
             exp2f(f));
    } else {
      double s, c;
      sincos(x, &s, &c);
      printf("%a %a %a %a %a %a %a %a %a %a %a %a\n", sin(x), exp(x), log(x),
             pow(x, 1.25), atan2(x, 0.75), s, c, tan(x), sinh(x), cosh(x),
             tanh(x), exp2(x));
    }
  }
  return 0;
}
