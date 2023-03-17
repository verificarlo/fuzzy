#!/usr/bin/env python3

import argparse
import os
import textwrap

ld_preload_file = '/etc/ld.so.preload'
fuzzy_libmath_root = '/opt/mca-libmath'

versions = [
    'no-fuzzy',
    'fast',
    'standard',
    'quad',
    'mpfr'
]

libmath_so = 'libmath.so'


def switch_version(version):
    try:
        with open(ld_preload_file, encoding='utf-8') as fi:
            current_so = fi.readline().strip().split()
    except FileNotFoundError:
        current_so = []

    new_so = [so for so in current_so if not so.startswith(fuzzy_libmath_root)]

    if version != 'no-fuzzy':
        new_version = os.path.join(fuzzy_libmath_root, version, libmath_so)
        new_so.append(new_version)

    to_write = " ".join(new_so)

    with open(ld_preload_file, "w", encoding='utf-8') as fo:
        fo.write(to_write)


def parse_args():
    help_msg = '''\
    Fuzzy libmath version to use:
        - no-fuzzy: Disable fuzzy libmath
        - fast:     Use the standard libmath available on the system.
                    Not possible to modify the virtual precision!
                    Fastest instrumentation but possibly not accurate
        - standard: Use the standard libmath available on the system.
                    Fast instrumentation but possibly not accurate
        - quad:     Use the libquadmath for intermediate results.
                    Slower than the standard version but more accurate.
        - mpfr:     Use the mpfr library for intermediate results.
                    Slowest version but gives the correct rounding.
    '''

    parser = argparse.ArgumentParser('set-fuzzy-libmath',
                                     formatter_class=argparse.RawTextHelpFormatter,
                                     epilog=textwrap.dedent(help_msg))
    parser.add_argument('--version', required=True, choices=versions,
                        action='store')
    args = parser.parse_args()
    return args


def main():
    args = parse_args()
    switch_version(args.version)


if '__main__' == __name__:
    main()
