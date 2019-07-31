# Installing Cython-scripts with Verificarlo

## Build Instructions
First, setup a container and enter it:

    docker build -t gkiar/cython-mca .
    docker run -ti -v ${PWD}:${PWD} -w ${PWD} gkiar/cython-mca

If necessary, clean up previous builds:

    ./manage.sh clean

Then, build using the specified mode:

    ./manage.sh mca  # To use verificarlo
    # OR
    ./manage.sh  # To use gcc

Finally, test the function compiled from `mca_ext.pyx`:

    ./manage.sh test <integer>


## Current status: failing with verificarlo
At present, when building with Verificarlo, the build appears successful but
ultimately it is failing to execute because of a "module not found" error in
Python, looking for somethign related to the mca verificarlo interface.
The exact stack trace is as follows:

    $ ./manage.sh test 10
    Traceback (most recent call last):
      File "<string>", line 1, in <module>
    ImportError: /home/users/gkiar/code/gkiar/stability-mca/code/verificarlo/cython/mca_ext.cpython-34m.so: undefined symbol: _vfc_current_mca_interface