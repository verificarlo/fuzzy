#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
//#include <math.h>

static double (*real_sqrt)(double dbl);
static float (*real_sqrtf)(float dbl);

//////////////////////////////////Override////////

double sqrt(double dbl)
{
    real_sqrt = dlsym(RTLD_NEXT, "sqrt");
    return real_sqrt(dbl) + 0.0;
}

float sqrtf(float dbl)
{
    real_sqrtf = dlsym(RTLD_NEXT, "sqrtf");
    return real_sqrtf(dbl) + 0.0;
}

