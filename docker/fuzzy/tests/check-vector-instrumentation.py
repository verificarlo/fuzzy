#!/usr/bin/python3
"""Check vector legalization, complete instrumentation, and RN/SR results."""
import ctypes
from fractions import Fraction
import os
from pathlib import Path
import re
import subprocess
import struct
import sys
import tempfile

if sys.argv[1] == '--runtime':
    library = ctypes.CDLL(sys.argv[2])
    mode = sys.argv[3]
    for typ, scalar, bits in [('float', ctypes.c_float, 23), ('double', ctypes.c_double, 52)]:
        a, b, c = Fraction(3, 2), 1 + Fraction(1, 2**bits), Fraction(1, 2**(bits+2))
        expected = {'add': a+b, 'sub': a-b, 'mul': a*b, 'div': a/b, 'fma': a*b+c}
        inputs = (scalar * 384)(*([float(a)]*128 + [float(b)]*128 + [float(c)]*128))
        for size in (1, 2, 3, 10, 12, 20, 32, 40, 64):
            for operation in expected:
                function = getattr(library, f'{operation}_{typ}{size}')
                function.argtypes = [ctypes.POINTER(scalar), ctypes.POINTER(scalar)]
                output = (scalar * 128)()
                results = []
                for _ in range(32):
                    function(output, inputs)
                    results.append(tuple(output[:size]))
                if mode == 'rn':
                    reference = scalar(float(expected[operation])).value
                    assert len(set(results)) == 1, (typ, size, operation, 'RN is not deterministic')
                    encoding = ('f', 'I') if typ == 'float' else ('d', 'Q')
                    def ordered(value):
                        return struct.unpack(encoding[1], struct.pack(encoding[0], value))[0]
                    # Match the image's accepted 16-ULP PRISM RN tolerance.
                    assert all(abs(ordered(value) - ordered(reference)) <= 16 for value in results[0]), (typ, size, operation, reference, results[:2])
                elif operation in ('add', 'mul', 'fma'):
                    assert len(set(results)) > 1, (typ, size, operation, 'no SR variation')
    raise SystemExit(0)

march = sys.argv[1]
flags = ['--prism-backend=sr', '--prism-backend-dispatch=static',
         '--prism-backend-strict-abi', '--inst-fma', f'-march={march}', '-O0', '-fPIC']
shapes = (1, 2, 3, 10, 12, 20, 32, 40, 64)
operations = {'add': 'a+b', 'sub': 'a-b', 'mul': 'a*b', 'div': 'a/b',
              'fma': '__builtin_elementwise_fma(a,b,c)'}
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    source = []
    for typ in ('float', 'double'):
        for size in shapes:
            vector = f'v_{typ}{size}'
            source.append(f'typedef {typ} {vector} __attribute__((ext_vector_type({size})));')
            for operation, expression in operations.items():
                name = f'{operation}_{typ}{size}'
                source.append(f'''void {name}({typ} *out, const {typ} *in) {{
                    {vector} a,b,c,r;
                    __builtin_memcpy(&a,in,sizeof(a));
                    __builtin_memcpy(&b,in+128,sizeof(b));
                    __builtin_memcpy(&c,in+256,sizeof(c));
                    r={expression}; __builtin_memcpy(out,&r,sizeof(r));
                }}''')
    path = root / 'vectors.c'
    path.write_text('\n'.join(source))
    subprocess.run(['verificarlo-c', *flags, '--emit-llvm', str(path), '-o', str(root/'vectors.bc')], check=True)
    ir = subprocess.check_output(['/usr/lib/llvm-20/bin/llvm-dis', str(root/'vectors.bc'), '-o', '-'], text=True)
    assert not re.search(r'= (?:fadd|fsub|fmul|fdiv)\b|call .*@llvm\.(?:fma|fmuladd)\.', ir), 'native FP arithmetic remains after PRISM'
    # Ensure the adapter preserves SIMD rather than scalarizing every lane.
    assert re.search(r'call .*prism.*(?:addf32x|addf64x)', ir), 'no vector PRISM calls'
    subprocess.run(['verificarlo-c', *flags, '-shared', str(path), '-o', str(root/'vectors.so')], check=True)
    # Separate processes are needed for fresh backend modes and seeds.
    for mode in ('rn', 'sr'):
        environment = dict(os.environ, VFC_BACKENDS=f'libinterflop_prism.so --mode={mode}')
        subprocess.run([sys.executable, __file__, '--runtime', str(root/'vectors.so'), mode], env=environment, check=True)
    print('[PASS] FP32/FP64 vectors 1,2,3,10,12,20,32,40,64: complete PRISM instrumentation, SIMD, RN and SR')
