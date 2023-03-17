
import argparse
import os
import subprocess
import sys
from enum import Enum, auto


class AutoName(Enum):
    def _generate_next_value_(name, start, count, last_values):
        return name


class Signatures(AutoName):
    UNIVARIATE = auto()
    BIVARIATE = auto()
    LGAMMA_R = auto()
    SINCOS = auto()


class Types(Enum):
    binary32 = "float"
    binary64 = "double"


gcc = 'gcc'
libraries = ['ref', 'fast', 'standard', 'quad', 'mpfr']
outputs_filename = 'outputs'
perf_filename = ''
check_noise_cmd = f"python3 check_result.py {outputs_filename}"
libmath_lib = 'libmath.so'
functions_list_root = 'data'
sample_profiling_default = 10**6

excluded_functions = {
    'ref': [],
    'fast': [],
    'standard': [],
    'quad': ['exp10', 'exp10f', 'lgammaf_r', 'lgamma_r', 'exp2', 'exp2f'],
    'mpfr': []
}

_envs_default = {
    "VFC_BACKENDS": 'libinterflop_mca.so --mode=rr --precision-binary64=53 --precision-binary32=24',
    "VFC_BACKENDS_LOGGER": 'False',
    "VFC_BACKENDS_SILENT_LOAD": 'True'
}


def get_envs():
    return {**_envs_default}


def shell(cmd, stdout=None, env=None, show_cmd=False, success_msg='', error_msg=''):
    try:
        if show_cmd:
            print(cmd)
        if env:
            cmd = f'export {get_exports(env)}; {cmd}'
        subprocess.run(cmd, stdout=stdout, shell=True, check=True)
        print(success_msg, end='\n' if success_msg != '' else '')
    except subprocess.CalledProcessError as e:
        print(e)
        print(error_msg)
        sys.exit(1)


def assert_noise(function, library):
    if function in excluded_functions[library]:
        print('Skip')
    else:
        shell(check_noise_cmd, success_msg="Successed", error_msg="Failed")


def compile(fptype, signature, function, profiling, sample):
    cmd = (f'{gcc} test.c -lm '
           f' -DREAL={fptype:8} -D{signature:10} '
           f' -DFUNCTION={function:10} {profiling} {sample} '
           f' -o test ')
    shell(cmd, error_msg='Compilation failed')


def get_exports(envs):
    return ' '.join([f'{name.upper()}="{value}"' for name, value in envs.items()])


def run(library, points):
    cmd = f'./test {" ".join(points)} > {outputs_filename}'
    env = get_envs()
    if library != 'ref':
        env['LD_PRELOAD'] = os.path.join(os.getcwd(),
                                         os.path.pardir, library, libmath_lib)
    shell(cmd, env=env)


def get_functions_list(signature, fptype):
    filename = f'math-functions-{fptype.name}-{signature.name.lower()}.txt'
    path = os.path.join(functions_list_root, filename)
    return path


def eval_library(signature, library, profiling, sample):
    for fptype in Types:
        functions_list = get_functions_list(signature, fptype)
        with open(functions_list) as fi:
            for line in fi:
                function, *points = line.strip().split()
                print(f'Evals {function:10} on {" ".join(points)}')
                compile(fptype.value, signature.name,
                        function, profiling, sample)
                run(library, points)
                if library != 'ref':
                    assert_noise(function, library)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--library', action='store', choices=libraries,
                        required=True, help="Libmath flavour to test")
    parser.add_argument('--profiling', action='store_true',
                        help='Run time profiling')
    parser.add_argument('--profiling-sample', action='store',
                        default=sample_profiling_default, help='Sample size for time profiling')
    args = parser.parse_args()
    return args


def main():
    args = parse_args()
    for signature in Signatures:
        library = args.library
        profiling = '-DPROFILING' if args.profiling else ''
        sample = f'-DN={args.profiling_sample}' if args.profiling else ''
        eval_library(signature,
                     library,
                     profiling,
                     sample)


if __name__ == '__main__':
    main()
