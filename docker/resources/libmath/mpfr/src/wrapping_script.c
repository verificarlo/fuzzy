#define _GNU_SOURCE
#include <dlfcn.h>
#include <mpfr.h>

#include "interflop/interflop.h"

__float128 mpfr_get_float128(mpfr_t op, mpfr_rnd_t rnd);

#define QUAD_PREC 113

#define GET_PRECISION(TYPE) _Generic(TYPE, float : 24, double : 53)

#ifdef NO_INSTRUMENTATION
#define INEXACT(X, RES)                                                        \
  do {                                                                         \
  } while (0);
#else
#define INEXACT(X, RES)                                                        \
  interflop_call(INTERFLOP_INEXACT_ID, FQUAD, &RES, GET_PRECISION(x))
#endif

#define DEFINE_1_WRAPPER(WRAPPER, INTERNAL, TYPE)                              \
  TYPE WRAPPER(TYPE x) {                                                       \
    MPFR_DECL_INIT(mpfr_x, QUAD_PREC);                                         \
    mpfr_set_d(mpfr_x, x, MPFR_RNDN);                                          \
    INTERNAL(mpfr_x, mpfr_x, MPFR_RNDN);                                       \
    __float128 res = mpfr_get_float128(mpfr_x, MPFR_RNDN);                     \
    INEXACT(x, res);                                                           \
    return (TYPE)res;                                                          \
  }

#define DEFINE_1i_1_WRAPPER(WRAPPER, INTERNAL, TYPE)                           \
  TYPE WRAPPER(int n, TYPE x) {                                                \
    MPFR_DECL_INIT(mpfr_x, QUAD_PREC);                                         \
    mpfr_set_d(mpfr_x, x, MPFR_RNDN);                                          \
    INTERNAL(mpfr_x, n, mpfr_x, MPFR_RNDN);                                    \
    __float128 res = mpfr_get_float128(mpfr_x, MPFR_RNDN);                     \
    INEXACT(x, res);                                                           \
    return (TYPE)res;                                                          \
  }

#define DEFINE_1_1p_WRAPPER(WRAPPER, INTERNAL, TYPE)                           \
  TYPE WRAPPER(TYPE x, int *s) {                                               \
    MPFR_DECL_INIT(mpfr_x, QUAD_PREC);                                         \
    mpfr_set_d(mpfr_x, x, MPFR_RNDN);                                          \
    INTERNAL(mpfr_x, s, mpfr_x, MPFR_RNDN);                                    \
    __float128 res = mpfr_get_float128(mpfr_x, MPFR_RNDN);                     \
    INEXACT(x, res);                                                           \
    return (TYPE)res;                                                          \
  }

#define DEFINE_1_2p_WRAPPER(WRAPPER, INTERNAL, TYPE)                           \
  void WRAPPER(TYPE x, TYPE *o1, TYPE *o2) {                                   \
    MPFR_DECL_INIT(mpfr_x, QUAD_PREC);                                         \
    MPFR_DECL_INIT(mpfr_o1, QUAD_PREC);                                        \
    MPFR_DECL_INIT(mpfr_o2, QUAD_PREC);                                        \
    mpfr_set_d(mpfr_x, x, MPFR_RNDN);                                          \
    INTERNAL(mpfr_o1, mpfr_o2, mpfr_x, MPFR_RNDN);                             \
    __float128 o1q = mpfr_get_float128(mpfr_o1, MPFR_RNDN);                    \
    __float128 o2q = mpfr_get_float128(mpfr_o2, MPFR_RNDN);                    \
    INEXACT(x, o1q);                                                           \
    INEXACT(x, o2q);                                                           \
    *o1 = o1q;                                                                 \
    *o2 = o2q;                                                                 \
  }

#define DEFINE_2_WRAPPER(WRAPPER, INTERNAL, TYPE)                              \
  TYPE WRAPPER(TYPE x, TYPE y) {                                               \
    MPFR_DECL_INIT(mpfr_x, QUAD_PREC);                                         \
    MPFR_DECL_INIT(mpfr_y, QUAD_PREC);                                         \
    mpfr_set_d(mpfr_x, x, MPFR_RNDN);                                          \
    mpfr_set_d(mpfr_y, y, MPFR_RNDN);                                          \
    INTERNAL(mpfr_x, mpfr_x, mpfr_y, MPFR_RNDN);                               \
    __float128 res = mpfr_get_float128(mpfr_x, MPFR_RNDN);                     \
    INEXACT(x, res);                                                           \
    return (TYPE)res;                                                          \
  }

DEFINE_1_WRAPPER(sqrt, mpfr_sqrt, double);
DEFINE_1_WRAPPER(sqrtf, mpfr_sqrt, float);

DEFINE_1_WRAPPER(cbrt, mpfr_cbrt, double);
DEFINE_1_WRAPPER(cbrtf, mpfr_cbrt, float);

DEFINE_2_WRAPPER(hypot, mpfr_hypot, double);
DEFINE_2_WRAPPER(hypotf, mpfr_hypot, float);

DEFINE_1_WRAPPER(logf, mpfr_log, float);
DEFINE_1_WRAPPER(log, mpfr_log, double);

DEFINE_1_WRAPPER(log10, mpfr_log10, double);
DEFINE_1_WRAPPER(log10f, mpfr_log10, float);

DEFINE_1_WRAPPER(log1p, mpfr_log1p, double);
DEFINE_1_WRAPPER(log1pf, mpfr_log1p, float);

DEFINE_1_WRAPPER(log2, mpfr_log2, double);
DEFINE_1_WRAPPER(log2f, mpfr_log2, float);

DEFINE_1_WRAPPER(sin, mpfr_sin, double);
DEFINE_1_WRAPPER(sinf, mpfr_sin, float);

DEFINE_1_WRAPPER(asin, mpfr_asin, double);
DEFINE_1_WRAPPER(asinf, mpfr_asin, float);

DEFINE_1_WRAPPER(asinh, mpfr_asinh, double);
DEFINE_1_WRAPPER(asinhf, mpfr_asinh, float);

DEFINE_1_WRAPPER(cos, mpfr_cos, double);
DEFINE_1_WRAPPER(cosf, mpfr_cos, float);

DEFINE_1_WRAPPER(acos, mpfr_acos, double);
DEFINE_1_WRAPPER(acosf, mpfr_acos, float);

DEFINE_1_WRAPPER(acosh, mpfr_acosh, double);
DEFINE_1_WRAPPER(acoshf, mpfr_acosh, float);

DEFINE_1_WRAPPER(atan, mpfr_atan, double);
DEFINE_1_WRAPPER(atanf, mpfr_atan, float);

DEFINE_1_WRAPPER(atanh, mpfr_atanh, double);
DEFINE_1_WRAPPER(atanhf, mpfr_atanh, float);

DEFINE_2_WRAPPER(atan2, mpfr_atan2, double);
DEFINE_2_WRAPPER(atan2f, mpfr_atan2, float);

DEFINE_1_WRAPPER(exp, mpfr_exp, double);
DEFINE_1_WRAPPER(expf, mpfr_exp, float);

DEFINE_2_WRAPPER(pow, mpfr_pow, double);
DEFINE_2_WRAPPER(powf, mpfr_pow, float);

DEFINE_1_WRAPPER(exp10, mpfr_exp10, double);
DEFINE_1_WRAPPER(exp10f, mpfr_exp10, float);

DEFINE_1_WRAPPER(exp2, mpfr_exp2, double);
DEFINE_1_WRAPPER(exp2f, mpfr_exp2, float);

DEFINE_1_WRAPPER(expm1, mpfr_expm1, double);
DEFINE_1_WRAPPER(expm1f, mpfr_expm1, float);

DEFINE_1_WRAPPER(j0, mpfr_j0, double);
DEFINE_1_WRAPPER(j0f, mpfr_j0, float);

DEFINE_1_WRAPPER(j1, mpfr_j1, double);
DEFINE_1_WRAPPER(j1f, mpfr_j1, float);

DEFINE_1i_1_WRAPPER(jn, mpfr_jn, double);
DEFINE_1i_1_WRAPPER(jnf, mpfr_jn, float);

DEFINE_1_WRAPPER(y0, mpfr_y0, double);
DEFINE_1_WRAPPER(y0f, mpfr_y0, float);

DEFINE_1_WRAPPER(y1, mpfr_y1, double);
DEFINE_1_WRAPPER(y1f, mpfr_y1, float);

DEFINE_1i_1_WRAPPER(yn, mpfr_yn, double);
DEFINE_1i_1_WRAPPER(ynf, mpfr_yn, float);

DEFINE_1_WRAPPER(erf, mpfr_erf, double);
DEFINE_1_WRAPPER(erff, mpfr_erf, float);

DEFINE_1_WRAPPER(erfc, mpfr_erfc, double);
DEFINE_1_WRAPPER(erfcf, mpfr_erfc, float);

DEFINE_1_WRAPPER(lgamma, mpfr_lngamma, double);
DEFINE_1_WRAPPER(lgammaf, mpfr_lngamma, float);

DEFINE_1_WRAPPER(tgamma, mpfr_gamma, double);
DEFINE_1_WRAPPER(tgammaf, mpfr_gamma, float);

DEFINE_1_1p_WRAPPER(lgamma_r, mpfr_lgamma, double);
DEFINE_1_1p_WRAPPER(lgammaf_r, mpfr_lgamma, float);

DEFINE_1_2p_WRAPPER(sincos, mpfr_sin_cos, double);
DEFINE_1_2p_WRAPPER(sincosf, mpfr_sin_cos, float);