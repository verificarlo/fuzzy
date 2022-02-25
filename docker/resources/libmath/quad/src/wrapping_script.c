#define _GNU_SOURCE
#include <dlfcn.h>
#include <interflop.h>
#include <quadmath.h>
#include <stdio.h>
#include <stdlib.h>

#define GET_PRECISION(TYPE) _Generic(TYPE, float : 24, double : 53)

#define DEFINE_1_WRAPPER(WRAPPER, INTERNAL, TYPE)                              \
  TYPE WRAPPER(TYPE x) {                                                       \
    __float128 res = INTERNAL(x);                                              \
    interflop_call(INTERFLOP_INEXACT_ID, FQUAD, &res, GET_PRECISION(x));       \
    return (TYPE)res;                                                          \
  }

#define DEFINE_1i_1_WRAPPER(WRAPPER, INTERNAL, TYPE)                           \
  TYPE WRAPPER(int n, TYPE x) {                                                \
    __float128 res = INTERNAL(n, x);                                           \
    interflop_call(INTERFLOP_INEXACT_ID, FQUAD, &res, GET_PRECISION(x));       \
    return res;                                                                \
  }

#define DEFINE_1_1p_WRAPPER(WRAPPER, INTERNAL, TYPE)                           \
  TYPE WRAPPER(TYPE x, int *s) {                                               \
    __float128 res = INTERNAL(x, s);                                           \
    interflop_call(INTERFLOP_INEXACT_ID, FQUAD, &res, GET_PRECISION(x));       \
    return res;                                                                \
  }

#define DEFINE_1_2p_WRAPPER(WRAPPER, INTERNAL, TYPE)                           \
  void WRAPPER(TYPE x, TYPE *o1, TYPE *o2) {                                   \
    __float128 o1q, o2q;                                                       \
    INTERNAL(x, &o1q, &o2q);                                                   \
    interflop_call(INTERFLOP_INEXACT_ID, FQUAD, &o1q, GET_PRECISION(x));       \
    interflop_call(INTERFLOP_INEXACT_ID, FQUAD, &o2q, GET_PRECISION(x));       \
    *o1 = o1q;                                                                 \
    *o2 = o2q;                                                                 \
  }

#define DEFINE_2_WRAPPER(WRAPPER, INTERNAL, TYPE)                              \
  TYPE WRAPPER(TYPE x, TYPE y) {                                               \
    __float128 res = INTERNAL(x, y);                                           \
    interflop_call(INTERFLOP_INEXACT_ID, FQUAD, &res, GET_PRECISION(x));       \
    return (TYPE)res;                                                          \
  }

DEFINE_1_WRAPPER(sqrt, sqrtq, double);
DEFINE_1_WRAPPER(sqrtf, sqrtq, float);

DEFINE_1_WRAPPER(cbrt, cbrtq, double);
DEFINE_1_WRAPPER(cbrtf, cbrtq, float);

DEFINE_2_WRAPPER(hypot, hypotq, double);
DEFINE_2_WRAPPER(hypotf, hypotq, float);

DEFINE_1_WRAPPER(logf, logq, float);
DEFINE_1_WRAPPER(log, logq, double);

DEFINE_1_WRAPPER(log10, log10q, double);
DEFINE_1_WRAPPER(log10f, log10q, float);

DEFINE_1_WRAPPER(log1p, log1pq, double);
DEFINE_1_WRAPPER(log1pf, log1pq, float);

DEFINE_1_WRAPPER(log2, log2q, double);
DEFINE_1_WRAPPER(log2f, log2q, float);

DEFINE_1_WRAPPER(sin, sinq, double);
DEFINE_1_WRAPPER(sinf, sinq, float);

DEFINE_1_WRAPPER(asin, asinq, double);
DEFINE_1_WRAPPER(asinf, asinq, float);

DEFINE_1_WRAPPER(asinh, asinhq, double);
DEFINE_1_WRAPPER(asinhf, asinhq, float);

DEFINE_1_WRAPPER(cos, cosq, double);
DEFINE_1_WRAPPER(cosf, cosq, float);

DEFINE_1_WRAPPER(acos, acosq, double);
DEFINE_1_WRAPPER(acosf, acosq, float);

DEFINE_1_WRAPPER(acosh, acoshq, double);
DEFINE_1_WRAPPER(acoshf, acoshq, float);

DEFINE_1_WRAPPER(atan, atanq, double);
DEFINE_1_WRAPPER(atanf, atanq, float);

DEFINE_1_WRAPPER(atanh, atanhq, double);
DEFINE_1_WRAPPER(atanhf, atanhq, float);

DEFINE_2_WRAPPER(atan2, atan2q, double);
DEFINE_2_WRAPPER(atan2f, atan2q, float);

DEFINE_1_WRAPPER(exp, expq, double);
DEFINE_1_WRAPPER(expf, expq, float);

DEFINE_2_WRAPPER(pow, powq, double);
DEFINE_2_WRAPPER(powf, powq, float);

// DEFINE_1_WRAPPER(exp10, exp10q, double);
// DEFINE_1_WRAPPER(exp10f, exp10q, float);

DEFINE_1_WRAPPER(exp2, exp2q, double);
DEFINE_1_WRAPPER(exp2f, exp2q, float);

DEFINE_1_WRAPPER(expm1, expm1q, double);
DEFINE_1_WRAPPER(expm1f, expm1q, float);

DEFINE_1_WRAPPER(j0, j0q, double);
DEFINE_1_WRAPPER(j0f, j0q, float);

DEFINE_1_WRAPPER(j1, j1q, double);
DEFINE_1_WRAPPER(j1f, j1q, float);

DEFINE_1i_1_WRAPPER(jn, jnq, double);
DEFINE_1i_1_WRAPPER(jnf, jnq, float);

DEFINE_1_WRAPPER(y0, y0q, double);
DEFINE_1_WRAPPER(y0f, y0q, float);

DEFINE_1_WRAPPER(y1, y1q, double);
DEFINE_1_WRAPPER(y1f, y1q, float);

DEFINE_1i_1_WRAPPER(yn, ynq, double);
DEFINE_1i_1_WRAPPER(ynf, ynq, float);

DEFINE_1_WRAPPER(erf, erfq, double);
DEFINE_1_WRAPPER(erff, erfq, float);

DEFINE_1_WRAPPER(erfc, erfcq, double);
DEFINE_1_WRAPPER(erfcf, erfcq, float);

DEFINE_1_WRAPPER(lgamma, lgammaq, double);
DEFINE_1_WRAPPER(lgammaf, lgammaq, float);

DEFINE_1_WRAPPER(tgamma, tgammaq, double);
DEFINE_1_WRAPPER(tgammaf, tgammaq, float);

// DEFINE_1_1p_WRAPPER(lgamma_r, double);
// DEFINE_1_1p_WRAPPER(lgammaf_r, float);

DEFINE_1_2p_WRAPPER(sincos, sincosq, double);
DEFINE_1_2p_WRAPPER(sincosf, sincosq, float);