#define _GNU_SOURCE
#include <dlfcn.h>
#include <interflop.h>
#include <stdio.h>
//#include <math.h>
#include <stdint.h>
#include <sys/time.h>

#include "float_struct.h"

#define xstr(s) str(s)
#define str(s) #s

// Algebraic functions
typedef double (*real_sqrt_t)(double dbl);
typedef float (*real_sqrtf_t)(float dbl);
typedef double (*real_cbrt_t)(double dbl);
typedef float (*real_cbrtf_t)(float dbl);
typedef double (*real_hypot_t)(double dbl1, double dbl2);
typedef float (*real_hypotf_t)(float dbl1, float dbl2);

// Elementary transcendental functions
typedef double (*real_log_t)(double dbl);
typedef float (*real_logf_t)(float dbl);
typedef double (*real_log10_t)(double dbl);
typedef float (*real_log10f_t)(float dbl);
typedef double (*real_log1p_t)(double dbl);
typedef float (*real_log1pf_t)(float dbl);
typedef double (*real_log2_t)(double dbl);
typedef float (*real_log2f_t)(float dbl);

typedef double (*real_sin_t)(double dbl);
typedef float (*real_sinf_t)(float dbl);
typedef double (*real_asin_t)(double dbl);
typedef float (*real_asinf_t)(float dbl);
typedef double (*real_asinh_t)(double dbl);
typedef float (*real_asinhf_t)(float dbl);

// Higher transcendental functions
typedef double (*real_cos_t)(double dbl);
typedef float (*real_cosf_t)(float dbl);
typedef double (*real_acos_t)(double dbl);
typedef float (*real_acosf_t)(float dbl);
typedef double (*real_acosh_t)(double dbl);
typedef float (*real_acoshf_t)(float dbl);
typedef double (*real_atan_t)(double dbl);
typedef float (*real_atanf_t)(float dbl);
typedef double (*real_atan2_t)(double dbl1, double dbl2);
typedef float (*real_atan2f_t)(float dbl1, float dbl2);
typedef double (*real_atanh_t)(double dbl);
typedef float (*real_atanhf_t)(float dbl);
typedef double (*real_exp_t)(double dbl);
typedef float (*real_expf_t)(float dbl);
typedef double (*real_exp10_t)(double dbl);
typedef float (*real_exp10f_t)(float dbl);
typedef double (*real_exp2_t)(double dbl);
typedef float (*real_exp2f_t)(float dbl);
typedef double (*real_expm1_t)(double dbl);
typedef float (*real_expm1f_t)(float dbl);
typedef double (*real_pow_t)(double dbl1, double dbl2);
typedef float (*real_powf_t)(float dbl1, float dbl2);

// Higher transcendental functions
typedef double (*real_j0_t)(double dbl);
typedef float (*real_j0f_t)(float dbl);
typedef double (*real_j1_t)(double dbl);
typedef float (*real_j1f_t)(float dbl);
typedef double (*real_jn_t)(int n, double dbl);
typedef float (*real_jnf_t)(int n, float dbl);
typedef double (*real_y0_t)(double dbl);
typedef float (*real_y0f_t)(float dbl);
typedef double (*real_y1_t)(double dbl);
typedef float (*real_y1f_t)(float dbl);
typedef double (*real_yn_t)(int n, double dbl);
typedef float (*real_ynf_t)(int n, float dbl);
typedef double (*real_erf_t)(double dbl);
typedef float (*real_erff_t)(float dbl);
typedef double (*real_erfc_t)(double dbl);
typedef float (*real_erfcf_t)(float dbl);
typedef double (*real_lgamma_t)(double dbl);
typedef float (*real_lgammaf_t)(float dbl);
typedef double (*real_tgamma_t)(double dbl);
typedef float (*real_tgammaf_t)(float dbl);

typedef double (*real_lgamma_r_t)(double dbl, int *signgamp);
typedef float (*real_lgammaf_r_t)(float dbl, int *signgamp);

typedef void (*real_sincos_t)(double dbl, double *sin, double *cos);
typedef void (*real_sincosf_t)(float dbl, float *sin, float *cos);

static real_sqrt_t real_sqrt = NULL;
static real_sqrtf_t real_sqrtf = NULL;
static real_cbrt_t real_cbrt = NULL;
static real_cbrtf_t real_cbrtf = NULL;
static real_hypot_t real_hypot = NULL;
static real_hypotf_t real_hypotf = NULL;

// Elementary transcendental functions
static real_log_t real_log = NULL;
static real_logf_t real_logf = NULL;
static real_log10_t real_log10 = NULL;
static real_log10f_t real_log10f = NULL;
static real_log1p_t real_log1p = NULL;
static real_log1pf_t real_log1pf = NULL;
static real_log2_t real_log2 = NULL;
static real_log2f_t real_log2f = NULL;

static real_sin_t real_sin = NULL;
static real_sinf_t real_sinf = NULL;
static real_asin_t real_asin = NULL;
static real_asinf_t real_asinf = NULL;
static real_asinh_t real_asinh = NULL;
static real_asinhf_t real_asinhf = NULL;

// Higher transcendental functions
static real_cos_t real_cos = NULL;
static real_cosf_t real_cosf = NULL;
static real_acos_t real_acos = NULL;
static real_acosf_t real_acosf = NULL;
static real_acosh_t real_acosh = NULL;
static real_acoshf_t real_acoshf = NULL;
static real_atan_t real_atan = NULL;
static real_atanf_t real_atanf = NULL;
static real_atan2_t real_atan2 = NULL;
static real_atan2f_t real_atan2f = NULL;
static real_atanh_t real_atanh = NULL;
static real_atanhf_t real_atanhf = NULL;
static real_exp_t real_exp = NULL;
static real_expf_t real_expf = NULL;
static real_exp10_t real_exp10 = NULL;
static real_exp10f_t real_exp10f = NULL;
static real_exp2_t real_exp2 = NULL;
static real_exp2f_t real_exp2f = NULL;
static real_expm1_t real_expm1 = NULL;
static real_expm1f_t real_expm1f = NULL;
static real_pow_t real_pow = NULL;
static real_powf_t real_powf = NULL;

// Higher transcendental functions
static real_j0_t real_j0 = NULL;
static real_j0f_t real_j0f = NULL;
static real_j1_t real_j1 = NULL;
static real_j1f_t real_j1f = NULL;
static real_jn_t real_jn = NULL;
static real_jnf_t real_jnf = NULL;
static real_y0_t real_y0 = NULL;
static real_y0f_t real_y0f = NULL;
static real_y1_t real_y1 = NULL;
static real_y1f_t real_y1f = NULL;
static real_yn_t real_yn = NULL;
static real_ynf_t real_ynf = NULL;
static real_erf_t real_erf = NULL;
static real_erff_t real_erff = NULL;
static real_erfc_t real_erfc = NULL;
static real_erfcf_t real_erfcf = NULL;
static real_lgamma_t real_lgamma = NULL;
static real_lgammaf_t real_lgammaf = NULL;
static real_tgamma_t real_tgamma = NULL;
static real_tgammaf_t real_tgammaf = NULL;

static real_lgamma_r_t real_lgamma_r = NULL;
static real_lgammaf_r_t real_lgammaf_r = NULL;

static real_sincos_t real_sincos = NULL;
static real_sincosf_t real_sincosf = NULL;

typedef enum real_functions {
  SQRT = 0,
  SQRTF,
  CBRT,
  CBRTF,
  HYPOT,
  HYPOTF,
  LOG,
  LOGF,
  LOG10,
  LOG10F,
  LOG1P,
  LOG1PF,
  LOG2,
  LOG2F,
  SIN,
  SINF,
  ASIN,
  ASINF,
  ASINH,
  ASINHF,
  COS,
  COSF,
  ACOS,
  ACOSF,
  ACOSH,
  ACOSHF,
  ATAN,
  ATANF,
  ATAN2,
  ATAN2F,
  ATANH,
  ATANHF,
  EXP,
  EXPF,
  EXP10,
  EXP10F,
  EXP2,
  EXP2F,
  EXPM1,
  EXPM1F,
  POW,
  POWF,
  J0,
  J0F,
  J1,
  J1F,
  JN,
  JNF,
  Y0,
  Y0F,
  Y1,
  Y1F,
  YN,
  YNF,
  ERF,
  ERFF,
  ERFC,
  ERFCF,
  LGAMMA,
  LGAMMAF,
  TGAMMA,
  TGAMMAF,
  LGAMMA_R,
  LGAMMAF_R,
  SINCOS,
  SINCOSF,
  __REAL_FUNCTION_END__
} real_functions_t;

void *real_functions[] = {[SQRT] = &real_sqrt,
                          [SQRTF] = &real_sqrtf,
                          [CBRT] = &real_cbrt,
                          [CBRTF] = &real_cbrtf,
                          [HYPOT] = &real_hypot,
                          [HYPOTF] = &real_hypotf,
                          [LOG] = &real_log,
                          [LOGF] = &real_logf,
                          [LOG10] = &real_log10,
                          [LOG10F] = &real_log10f,
                          [LOG1P] = &real_log1p,
                          [LOG1PF] = &real_log1pf,
                          [LOG2] = &real_log2,
                          [LOG2F] = &real_log2f,
                          [SIN] = &real_sin,
                          [SINF] = &real_sinf,
                          [ASIN] = &real_asin,
                          [ASINF] = &real_asinf,
                          [ASINH] = &real_asinh,
                          [ASINHF] = &real_asinhf,
                          [COS] = &real_cos,
                          [COSF] = &real_cosf,
                          [ACOS] = &real_acos,
                          [ACOSF] = &real_acosf,
                          [ACOSH] = &real_acosh,
                          [ACOSHF] = &real_acoshf,
                          [ATAN] = &real_atan,
                          [ATANF] = &real_atanf,
                          [ATAN2] = &real_atan2,
                          [ATAN2F] = &real_atan2f,
                          [ATANH] = &real_atanh,
                          [ATANHF] = &real_atanhf,
                          [EXP] = &real_exp,
                          [EXPF] = &real_expf,
                          [EXP10] = &real_exp10,
                          [EXP10F] = &real_exp10f,
                          [EXP2] = &real_exp2,
                          [EXP2F] = &real_exp2f,
                          [EXPM1] = &real_expm1,
                          [EXPM1F] = &real_expm1f,
                          [POW] = &real_pow,
                          [POWF] = &real_powf,
                          [J0] = &real_j0,
                          [J0F] = &real_j0f,
                          [J1] = &real_j1,
                          [J1F] = &real_j1f,
                          [JN] = &real_jn,
                          [JNF] = &real_jnf,
                          [Y0] = &real_y0,
                          [Y0F] = &real_y0f,
                          [Y1] = &real_y1,
                          [Y1F] = &real_y1f,
                          [YN] = &real_yn,
                          [YNF] = &real_ynf,
                          [ERF] = &real_erf,
                          [ERFF] = &real_erff,
                          [ERFC] = &real_erfc,
                          [ERFCF] = &real_erfcf,
                          [LGAMMA] = &real_lgamma,
                          [LGAMMAF] = &real_lgammaf,
                          [TGAMMA] = &real_tgamma,
                          [TGAMMAF] = &real_tgammaf,
                          [LGAMMA_R] = &real_lgamma_r,
                          [LGAMMAF_R] = &real_lgammaf_r,
                          [SINCOS] = &real_sincos,
                          [SINCOSF] = &real_sincosf,
                          [__REAL_FUNCTION_END__] = NULL};

typedef uint64_t xoroshiro_state[2];
static xoroshiro_state rng_state;

uint64_t next_seed(uint64_t seed_state) {
  uint64_t z = (seed_state += UINT64_C(0x9E3779B97F4A7C15));
  z = (z ^ (z >> 30)) * UINT64_C(0xBF58476D1CE4E5B9);
  z = (z ^ (z >> 27)) * UINT64_C(0x94D049BB133111EB);
  return z ^ (z >> 31);
}

static inline uint64_t rotl(const uint64_t x, int k) {
  return (x << k) | (x >> (64 - k));
}

uint64_t next(xoroshiro_state s) {
  const uint64_t s0 = s[0];
  uint64_t s1 = s[1];
  const uint64_t result = rotl(s0 + s1, 17) + s0;

  s1 ^= s0;
  s[0] = rotl(s0, 49) ^ s1 ^ (s1 << 21); // a, b
  s[1] = rotl(s1, 28);                   // c

  return result;
}

__attribute__((constructor(0))) static void fuzzy_init(void) {

  struct timeval t1;
  gettimeofday(&t1, NULL);
  uint64_t seed = t1.tv_sec ^ t1.tv_usec;
  rng_state[0] = next_seed(seed);
  rng_state[1] = next_seed(seed);

  real_functions[SQRT] = (real_sqrt_t)dlsym(RTLD_NEXT, "sqrt");
  real_functions[SQRTF] = (real_sqrtf_t)dlsym(RTLD_NEXT, "sqrtf");
  real_functions[CBRT] = (real_cbrt_t)dlsym(RTLD_NEXT, "cbrt");
  real_functions[CBRTF] = (real_cbrtf_t)dlsym(RTLD_NEXT, "cbrtf");
  real_functions[HYPOT] = (real_hypot_t)dlsym(RTLD_NEXT, "hypot");
  real_functions[HYPOTF] = (real_hypotf_t)dlsym(RTLD_NEXT, "hypotf");
  real_functions[LOG] = (real_log_t)dlsym(RTLD_NEXT, "log");
  real_functions[LOGF] = (real_logf_t)dlsym(RTLD_NEXT, "logf");
  real_functions[LOG10] = (real_log10_t)dlsym(RTLD_NEXT, "log10");
  real_functions[LOG10F] = (real_log10f_t)dlsym(RTLD_NEXT, "log10f");
  real_functions[LOG1P] = (real_log1p_t)dlsym(RTLD_NEXT, "log1p");
  real_functions[LOG1PF] = (real_log1pf_t)dlsym(RTLD_NEXT, "log1pf");
  real_functions[LOG2] = (real_log2_t)dlsym(RTLD_NEXT, "log2");
  real_functions[LOG2F] = (real_log2f_t)dlsym(RTLD_NEXT, "log2f");
  real_functions[SIN] = (real_sin_t)dlsym(RTLD_NEXT, "sin");
  real_functions[SINF] = (real_sinf_t)dlsym(RTLD_NEXT, "sinf");
  real_functions[ASIN] = (real_asin_t)dlsym(RTLD_NEXT, "asin");
  real_functions[ASINF] = (real_asinf_t)dlsym(RTLD_NEXT, "asinf");
  real_functions[ASINH] = (real_asinh_t)dlsym(RTLD_NEXT, "asinh");
  real_functions[ASINHF] = (real_asinhf_t)dlsym(RTLD_NEXT, "asinhf");
  real_functions[COS] = (real_cos_t)dlsym(RTLD_NEXT, "cos");
  real_functions[COSF] = (real_cosf_t)dlsym(RTLD_NEXT, "cosf");
  real_functions[ACOS] = (real_acos_t)dlsym(RTLD_NEXT, "acos");
  real_functions[ACOSF] = (real_acosf_t)dlsym(RTLD_NEXT, "acosf");
  real_functions[ACOSH] = (real_acosh_t)dlsym(RTLD_NEXT, "acosh");
  real_functions[ACOSHF] = (real_acoshf_t)dlsym(RTLD_NEXT, "acoshf");
  real_functions[ATAN] = (real_atan_t)dlsym(RTLD_NEXT, "atan");
  real_functions[ATANF] = (real_atanf_t)dlsym(RTLD_NEXT, "atanf");
  real_functions[ATAN2] = (real_atan2_t)dlsym(RTLD_NEXT, "atan2");
  real_functions[ATAN2F] = (real_atan2f_t)dlsym(RTLD_NEXT, "atan2f");
  real_functions[ATANH] = (real_atanh_t)dlsym(RTLD_NEXT, "atanh");
  real_functions[ATANHF] = (real_atanhf_t)dlsym(RTLD_NEXT, "atanhf");
  real_functions[EXP] = (real_exp_t)dlsym(RTLD_NEXT, "exp");
  real_functions[EXPF] = (real_expf_t)dlsym(RTLD_NEXT, "expf");
  real_functions[EXP10] = (real_exp10_t)dlsym(RTLD_NEXT, "exp10");
  real_functions[EXP10F] = (real_exp10f_t)dlsym(RTLD_NEXT, "exp10f");
  real_functions[EXP2] = (real_exp2_t)dlsym(RTLD_NEXT, "exp2");
  real_functions[EXP2F] = (real_exp2f_t)dlsym(RTLD_NEXT, "exp2f");
  real_functions[EXPM1] = (real_expm1_t)dlsym(RTLD_NEXT, "expm1");
  real_functions[EXPM1F] = (real_expm1f_t)dlsym(RTLD_NEXT, "expm1f");
  real_functions[POW] = (real_pow_t)dlsym(RTLD_NEXT, "pow");
  real_functions[POWF] = (real_powf_t)dlsym(RTLD_NEXT, "powf");
  real_functions[J0] = (real_j0_t)dlsym(RTLD_NEXT, "j0");
  real_functions[J0F] = (real_j0f_t)dlsym(RTLD_NEXT, "j0f");
  real_functions[J1] = (real_j1_t)dlsym(RTLD_NEXT, "j1");
  real_functions[J1F] = (real_j1f_t)dlsym(RTLD_NEXT, "j1f");
  real_functions[JN] = (real_jn_t)dlsym(RTLD_NEXT, "jn");
  real_functions[JNF] = (real_jnf_t)dlsym(RTLD_NEXT, "jnf");
  real_functions[Y0] = (real_y0_t)dlsym(RTLD_NEXT, "y0");
  real_functions[Y0F] = (real_y0f_t)dlsym(RTLD_NEXT, "y0f");
  real_functions[Y1] = (real_y1_t)dlsym(RTLD_NEXT, "y1");
  real_functions[Y1F] = (real_y1f_t)dlsym(RTLD_NEXT, "y1f");
  real_functions[YN] = (real_yn_t)dlsym(RTLD_NEXT, "yn");
  real_functions[YNF] = (real_ynf_t)dlsym(RTLD_NEXT, "ynf");
  real_functions[ERF] = (real_erf_t)dlsym(RTLD_NEXT, "erf");
  real_functions[ERFF] = (real_erff_t)dlsym(RTLD_NEXT, "erff");
  real_functions[ERFC] = (real_erfc_t)dlsym(RTLD_NEXT, "erfc");
  real_functions[ERFCF] = (real_erfcf_t)dlsym(RTLD_NEXT, "erfcf");
  real_functions[LGAMMA] = (real_lgamma_t)dlsym(RTLD_NEXT, "lgamma");
  real_functions[LGAMMAF] = (real_lgammaf_t)dlsym(RTLD_NEXT, "lgammaf");
  real_functions[TGAMMA] = (real_tgamma_t)dlsym(RTLD_NEXT, "tgamma");
  real_functions[TGAMMAF] = (real_tgammaf_t)dlsym(RTLD_NEXT, "tgammaf");
  real_functions[LGAMMA_R] = (real_lgamma_r_t)dlsym(RTLD_NEXT, "lgamma_r");
  real_functions[LGAMMAF_R] = (real_lgammaf_r_t)dlsym(RTLD_NEXT, "lgammaf_r");
  real_functions[SINCOS] = (real_sincos_t)dlsym(RTLD_NEXT, "sincos");
  real_functions[SINCOSF] = (real_sincosf_t)dlsym(RTLD_NEXT, "sincosf");
}

// Override

#define ZERO(TYPE) _Generic(TYPE, float : 0.0f, double : 0.0)
#define GET_FTYPE(TYPE) _Generic(TYPE, float : FFLOAT, double : FDOUBLE)

static inline void float_rr(float *a) {
  if (*a == 0.0)
    return;
  binary32 *b32 = (binary32 *)a;
  b32->u32 += (next(rng_state) & 1) ? 1 : -1;
}

static inline void double_rr(double *a) {
  if (*a == 0.0)
    return;
  binary64 *b64 = (binary64 *)a;
  b64->u64 += (next(rng_state) & 1) ? 1 : -1;
}

#define FP_RR(X) _Generic(X, float * : float_rr, double * : double_rr)(X)

#define DEFINE_1_WRAPPER(NAME, SYM, TYPE)                                      \
  TYPE NAME(TYPE x) {                                                          \
    real_##NAME##_t fun = real_functions[SYM];                                 \
    TYPE res = fun(x);                                                         \
    FP_RR(&res);                                                               \
    return res;                                                                \
  }

#define DEFINE_1i_1_WRAPPER(NAME, SYM, TYPE)                                   \
  TYPE NAME(int n, TYPE x) {                                                   \
    real_##NAME##_t fun = real_functions[SYM];                                 \
    TYPE res = fun(n, x);                                                      \
    FP_RR(&res);                                                               \
    return res;                                                                \
  }

#define DEFINE_1_1p_WRAPPER(NAME, SYM, TYPE)                                   \
  TYPE NAME(TYPE x, int *s) {                                                  \
    real_##NAME##_t fun = real_functions[SYM];                                 \
    TYPE res = fun(x, s);                                                      \
    FP_RR(&res);                                                               \
    return res;                                                                \
  }

#define DEFINE_1_2p_WRAPPER(NAME, SYM, TYPE)                                   \
  void NAME(TYPE x, TYPE *o1, TYPE *o2) {                                      \
    real_##NAME##_t fun = real_functions[SYM];                                 \
    fun(x, o1, o2);                                                            \
    FP_RR(o1);                                                                 \
    FP_RR(o2);                                                                 \
  }

#define DEFINE_2_WRAPPER(NAME, SYM, TYPE)                                      \
  TYPE NAME(TYPE x, TYPE y) {                                                  \
    real_##NAME##_t fun = real_functions[SYM];                                 \
    TYPE res = fun(x, y);                                                      \
    FP_RR(&res);                                                               \
    return res;                                                                \
  }

DEFINE_1_WRAPPER(sqrt, SQRT, double);
DEFINE_1_WRAPPER(sqrtf, SQRTF, float);

DEFINE_1_WRAPPER(cbrt, CBRT, double);
DEFINE_1_WRAPPER(cbrtf, CBRTF, float);

DEFINE_2_WRAPPER(hypot, HYPOT, double);
DEFINE_2_WRAPPER(hypotf, HYPOTF, float);

DEFINE_1_WRAPPER(log, LOG, double);
DEFINE_1_WRAPPER(logf, LOGF, float);

DEFINE_1_WRAPPER(log10, LOG10, double);
DEFINE_1_WRAPPER(log10f, LOG10F, float);

DEFINE_1_WRAPPER(log1p, LOG1P, double);
DEFINE_1_WRAPPER(log1pf, LOG1PF, float);

DEFINE_1_WRAPPER(log2, LOG2, double);
DEFINE_1_WRAPPER(log2f, LOG2F, float);

DEFINE_1_WRAPPER(sin, SIN, double);
DEFINE_1_WRAPPER(sinf, SINF, float);

DEFINE_1_WRAPPER(asin, ASIN, double);
DEFINE_1_WRAPPER(asinf, ASINF, float);

DEFINE_1_WRAPPER(asinh, ASINH, double);
DEFINE_1_WRAPPER(asinhf, ASINHF, float);

DEFINE_1_WRAPPER(cos, COS, double);
DEFINE_1_WRAPPER(cosf, COSF, float);

DEFINE_1_WRAPPER(acos, ACOS, double);
DEFINE_1_WRAPPER(acosf, ACOSF, float);

DEFINE_1_WRAPPER(acosh, ACOSH, double);
DEFINE_1_WRAPPER(acoshf, ACOSHF, float);

DEFINE_1_WRAPPER(atan, ATAN, double);
DEFINE_1_WRAPPER(atanf, ATANF, float);

DEFINE_1_WRAPPER(atanh, ATANH, double);
DEFINE_1_WRAPPER(atanhf, ATANHF, float);

DEFINE_2_WRAPPER(atan2, ATAN2, double);
DEFINE_2_WRAPPER(atan2f, ATAN2F, float);

DEFINE_1_WRAPPER(exp, EXP, double);
DEFINE_1_WRAPPER(expf, EXPF, float);

DEFINE_2_WRAPPER(pow, POW, double);
DEFINE_2_WRAPPER(powf, POWF, float);

DEFINE_1_WRAPPER(exp10, EXP10, double);
DEFINE_1_WRAPPER(exp10f, EXP10F, float);

DEFINE_1_WRAPPER(exp2, EXP2, double);
DEFINE_1_WRAPPER(exp2f, EXP2F, float);

DEFINE_1_WRAPPER(expm1, EXPM1, double);
DEFINE_1_WRAPPER(expm1f, EXPM1F, float);

DEFINE_1_WRAPPER(j0, J0, double);
DEFINE_1_WRAPPER(j0f, J0F, float);

DEFINE_1_WRAPPER(j1, J1, double);
DEFINE_1_WRAPPER(j1f, J1F, float);

DEFINE_1i_1_WRAPPER(jn, JN, double);
DEFINE_1i_1_WRAPPER(jnf, JNF, float);

DEFINE_1_WRAPPER(y0, Y0, double);
DEFINE_1_WRAPPER(y0f, Y0F, float);

DEFINE_1_WRAPPER(y1, Y1, double);
DEFINE_1_WRAPPER(y1f, Y1F, float);

DEFINE_1i_1_WRAPPER(yn, YN, double);
DEFINE_1i_1_WRAPPER(ynf, YNF, float);

DEFINE_1_WRAPPER(erf, ERF, double);
DEFINE_1_WRAPPER(erff, ERFF, float);

DEFINE_1_WRAPPER(erfc, ERFC, double);
DEFINE_1_WRAPPER(erfcf, ERFCF, float);

DEFINE_1_WRAPPER(lgamma, LGAMMA, double);
DEFINE_1_WRAPPER(lgammaf, LGAMMAF, float);

DEFINE_1_WRAPPER(tgamma, TGAMMA, double);
DEFINE_1_WRAPPER(tgammaf, TGAMMAF, float);

DEFINE_1_1p_WRAPPER(lgamma_r, LGAMMA_R, double);
DEFINE_1_1p_WRAPPER(lgammaf_r, LGAMMAF_R, float);

DEFINE_1_2p_WRAPPER(sincos, SINCOS, double);
DEFINE_1_2p_WRAPPER(sincosf, SINCOSF, float);
