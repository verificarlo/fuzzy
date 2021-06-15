#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
//#include <math.h>

#define xstr(s) str(s)
#define str(s) #s

// Algebraic functions
static double (*real_sqrt)(double dbl);
static float (*real_sqrtf)(float dbl);
static double (*real_cbrt)(double dbl);
static float (*real_cbrtf)(float dbl);
static double (*real_hypot)(double dbl1, double dbl2);
static float (*real_hypotf)(float dbl1, float dbl2);

// Elementary transcendental functions
static double (*real_log)(double dbl);
static float (*real_logf)(float dbl);
static double (*real_log10)(double dbl);
static float (*real_log10f)(float dbl);
static double (*real_log1p)(double dbl);
static float (*real_log1pf)(float dbl);
static double (*real_log2)(double dbl);
static float (*real_log2f)(float dbl);

static double (*real_sin)(double dbl);
static float (*real_sinf)(float dbl);
static double (*real_asin)(double dbl);
static float (*real_asinf)(float dbl);
static double (*real_asinh)(double dbl);
static float (*real_asinhf)(float dbl);

// Higher transcendental functions
static double (*real_cos)(double dbl);
static float (*real_cosf)(float dbl);
static double (*real_acos)(double dbl);
static float (*real_acosf)(float dbl);
static double (*real_acosh)(double dbl);
static float (*real_acoshf)(float dbl);
static double (*real_atan)(double dbl);
static float (*real_atanf)(float dbl);
static double (*real_atan2)(double dbl1, double dbl2);
static float (*real_atan2f)(float dbl1, float dbl2);
static double (*real_atanh)(double dbl);
static float (*real_atanhf)(float dbl);
static double (*real_exp)(double dbl);
static float (*real_expf)(float dbl);
static double (*real_exp10)(double dbl);
static float (*real_exp10f)(float dbl);
static double (*real_exp2)(double dbl);
static float (*real_exp2f)(float dbl);
static double (*real_expm1)(double dbl);
static float (*real_expm1f)(float dbl);
static double (*real_pow)(double dbl1, double dbl2);
static float (*real_powf)(float dbl1, float dbl2);

// Higher transcendental functions
static double (*real_j0)(double dbl);
static float (*real_j0f)(float dbl);
static double (*real_j1)(double dbl);
static float (*real_j1f)(float dbl);
static double (*real_jn)(int n, double dbl);
static float (*real_jnf)(int n, float dbl);
static double (*real_y0)(double dbl);
static float (*real_y0f)(float dbl);
static double (*real_y1)(double dbl);
static float (*real_y1f)(float dbl);
static double (*real_yn)(int n, double dbl);
static float (*real_ynf)(int n, float dbl);
static double (*real_erf)(double dbl);
static float (*real_erff)(float dbl);
static double (*real_erfc)(double dbl);
static float (*real_erfcf)(float dbl);
static double (*real_lgamma)(double dbl);
static float (*real_lgammaf)(float dbl);
static double (*real_tgamma)(double dbl);
static float (*real_tgammaf)(float dbl);

static double (*real_lgamma_r)(double dbl, int *signgamp);
static float (*real_lgammaf_r)(float dbl, int *signgamp);

static void (*real_sincos)(double dbl, double *sin, double *cos);
static void (*real_sincosf)(float dbl, float *sin, float *cos);

// Override

#define ZERO(TYPE) _Generic(TYPE, float : 0.0f, double : 0.0)

#define DEFINE_1_WRAPPER(NAME, TYPE)                                           \
  TYPE NAME(TYPE x) {                                                          \
    real_##NAME = dlsym(RTLD_NEXT, #NAME);                                     \
    return real_##NAME(x) + ZERO(x);                                           \
  }

#define DEFINE_1i_1_WRAPPER(NAME, TYPE)                                        \
  TYPE NAME(int n, TYPE x) {                                                   \
    real_##NAME = dlsym(RTLD_NEXT, #NAME);                                     \
    return real_##NAME(n, x) + ZERO(x);                                        \
  }

#define DEFINE_1_1p_WRAPPER(NAME, TYPE)                                        \
  TYPE NAME(TYPE x, int *s) {                                                  \
    real_##NAME = dlsym(RTLD_NEXT, #NAME);                                     \
    return real_##NAME(x, s) + ZERO(x);                                        \
  }

#define DEFINE_1_2p_WRAPPER(NAME, TYPE)                                        \
  void NAME(TYPE x, TYPE *o1, TYPE *o2) {                                      \
    real_##NAME = dlsym(RTLD_NEXT, #NAME);                                     \
    real_##NAME(x, o1, o2);                                                    \
    *o1 += ZERO(x);                                                            \
    *o2 += ZERO(x);                                                            \
  }

#define DEFINE_2_WRAPPER(NAME, TYPE)                                           \
  TYPE NAME(TYPE x, TYPE y) {                                                  \
    real_##NAME = dlsym(RTLD_NEXT, #NAME);                                     \
    return real_##NAME(x, y) + ZERO(x);                                        \
  }

DEFINE_1_WRAPPER(sqrt, double);
DEFINE_1_WRAPPER(sqrtf, float);

DEFINE_1_WRAPPER(cbrt, double);
DEFINE_1_WRAPPER(cbrtf, float);

DEFINE_2_WRAPPER(hypot, double);
DEFINE_2_WRAPPER(hypotf, float);

DEFINE_1_WRAPPER(log, double);
DEFINE_1_WRAPPER(logf, float);

DEFINE_1_WRAPPER(log10, double);
DEFINE_1_WRAPPER(log10f, float);

DEFINE_1_WRAPPER(log1p, double);
DEFINE_1_WRAPPER(log1pf, float);

DEFINE_1_WRAPPER(log2, double);
DEFINE_1_WRAPPER(log2f, float);

DEFINE_1_WRAPPER(sin, double);
DEFINE_1_WRAPPER(sinf, float);

DEFINE_1_WRAPPER(asin, double);
DEFINE_1_WRAPPER(asinf, float);

DEFINE_1_WRAPPER(asinh, double);
DEFINE_1_WRAPPER(asinhf, float);

DEFINE_1_WRAPPER(cos, double);
DEFINE_1_WRAPPER(cosf, float);

DEFINE_1_WRAPPER(acos, double);
DEFINE_1_WRAPPER(acosf, float);

DEFINE_1_WRAPPER(acosh, double);
DEFINE_1_WRAPPER(acoshf, float);

DEFINE_1_WRAPPER(atan, double);
DEFINE_1_WRAPPER(atanf, float);

DEFINE_1_WRAPPER(atanh, double);
DEFINE_1_WRAPPER(atanhf, float);

DEFINE_2_WRAPPER(atan2, double);
DEFINE_2_WRAPPER(atan2f, float);

DEFINE_1_WRAPPER(exp, double);
DEFINE_1_WRAPPER(expf, float);

DEFINE_2_WRAPPER(pow, double);
DEFINE_2_WRAPPER(powf, float);

DEFINE_1_WRAPPER(exp10, double);
DEFINE_1_WRAPPER(exp10f, float);

DEFINE_1_WRAPPER(exp2, double);
DEFINE_1_WRAPPER(exp2f, float);

DEFINE_1_WRAPPER(expm1, double);
DEFINE_1_WRAPPER(expm1f, float);

DEFINE_1_WRAPPER(j0, double);
DEFINE_1_WRAPPER(j0f, float);

DEFINE_1_WRAPPER(j1, double);
DEFINE_1_WRAPPER(j1f, float);

DEFINE_1i_1_WRAPPER(jn, double);
DEFINE_1i_1_WRAPPER(jnf, float);

DEFINE_1_WRAPPER(y0, double);
DEFINE_1_WRAPPER(y0f, float);

DEFINE_1_WRAPPER(y1, double);
DEFINE_1_WRAPPER(y1f, float);

DEFINE_1i_1_WRAPPER(yn, double);
DEFINE_1i_1_WRAPPER(ynf, float);

DEFINE_1_WRAPPER(erf, double);
DEFINE_1_WRAPPER(erff, float);

DEFINE_1_WRAPPER(erfc, double);
DEFINE_1_WRAPPER(erfcf, float);

DEFINE_1_WRAPPER(lgamma, double);
DEFINE_1_WRAPPER(lgammaf, float);

DEFINE_1_WRAPPER(tgamma, double);
DEFINE_1_WRAPPER(tgammaf, float);

DEFINE_1_1p_WRAPPER(lgamma_r, double);
DEFINE_1_1p_WRAPPER(lgammaf_r, float);

DEFINE_1_2p_WRAPPER(sincos, double);
DEFINE_1_2p_WRAPPER(sincosf, float);