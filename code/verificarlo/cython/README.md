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

