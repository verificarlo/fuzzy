# Recompiling Python with Verificarlo

## Build Instructions

Try building the container as follows:

    docker build -t gkiar/fuzzy-python .

## Current status

The end of the stack trace is as follows. From my novice-debugging, it looks as
though the value `linux` is being passed as a variable name rather than a string.

```
verificarlo -pthread -c -Wno-unused-result -Wsign-compare -Wunreachable-code -DNDEBUG -g  -O3 -Wall -Wstrict-prototypes    -std=c99 -Wextra -Wno-unused-result -Wno-unused-parameter -Wno-missing-field-initializers   -I. -I./Include    -DPy_BUILD_CORE -o Python/getversion.o Python/getversion.c
clang: warning: argument unused during compilation: '-I .'
clang: warning: argument unused during compilation: '-I ./Include'
./Python/getplatform.c:11:9: error: use of undeclared identifier 'linux'
        return PLATFORM;
               ^
<command line>:3:18: note: expanded from here
#define PLATFORM linux
                 ^
1 error generated.
/usr/local/bin/verificarlo: command failed:
/usr/lib/llvm-3.5/bin//clang -c -S ./Python/getplatform.c -emit-llvm -pthread -Wno-unused-result -Wsign-compare -Wunreachable-code -DNDEBUG -g -O3 -Wall -Wstrict-prototypes -std=c99 -Wextra -Wno-unused-result -Wno-unused-parameter -Wno-missing-field-initializers -I. -I./Include -DPy_BUILD_CORE -DPLATFORM="linux" -o ./Python/getplatform.1.ll
make[2]: *** [Python/getplatform.o] Error 1
make[2]: *** Waiting for unfinished jobs....
clang: warning: argument unused during compilation: '-I .'
clang: warning: argument unused during compilation: '-I ./Include'
clang: warning: argument unused during compilation: '-I .'
clang: warning: argument unused during compilation: '-I ./Include'
clang: warning: argument unused during compilation: '-I .'
clang: warning: argument unused during compilation: '-I ./Include'
make[2]: Leaving directory `/opt/build/Python-3.6.5'
make[1]: *** [build_all_generate_profile] Error 2
make[1]: Leaving directory `/opt/build/Python-3.6.5'
make: *** [profile-opt] Error 2
The command '/bin/sh -c cd /opt/build/Python-3.6.5 &&     make -j 8' returned a non-zero code: 2
```