FROM verificarlo/verificarlo:latest

RUN apt-get update -qqq &&\
    apt-get install -y -qqq make build-essential libssl-dev zlib1g-dev \
                            libbz2-dev libreadline-dev libsqlite3-dev wget \
                            curl llvm libncurses5-dev  libncursesw5-dev \
                            xz-utils tk-dev wget fort77 gfortran cmake &&\
    rm -rf /var/lib/apt/lists/ &&\
    mkdir -p /opt/build/

# Copy verificarlo's exclusion file for Python 3
COPY python-vfc-exclude.txt /tmp/python-vfc-exclude.txt

# Setting compilers and linkers to use verificarlo
# ... When compiling C, use exclusion file
ENV CC "verificarlo --exclude-file /tmp/python-vfc-exclude.txt"
ENV CXX "verificarlo"
ENV FC "verificarlo"
ENV LD "verificarlo"
ENV LDSHARED "verificarlo -shared"

# Replace IEEE with MCA and MPFR with QUAD after build
ENV VERIFICARLO_MCAMODE "IEEE"
ENV VERIFICARLO_PRECISION "53"
ENV VERIFICARLO_BACKEND "MPFR"

## Build Python 3.6.5 from source and the associated pip
RUN cd /opt/build/ && \
    wget https://www.python.org/ftp/python/3.6.5/Python-3.6.5.tgz && \
    tar xvf Python-3.6.5.tgz && \
    cd Python-3.6.5 && \
    ./configure --enable-optimizations --with-ensurepip=install &&\
    make &&\
    ln -s /opt/build/Python-3.6.5/python /usr/local/bin/python3.6 &&\
    cp pyconfig.h Include/*.h /usr/local/include/ &&\
    wget https://bootstrap.pypa.io/get-pip.py &&\
    python3.6 get-pip.py

# Build BLAS and LAPACK from the following URL's instructions:
#  http://ab-initio.mit.edu/wiki/index.php/Template:Installing_BLAS_and_LAPACK
RUN cd /opt/build/ &&\
    wget http://www.netlib.org/lapack/lapack-3.5.0.tgz &&\
    gunzip lapack-3.5.0.tgz &&\
    tar xf lapack-3.5.0.tar &&\
    cd /opt/build/lapack-3.5.0/ &&\
    cp make.inc.example make.inc &&\
    sed -i 's/= gcc\|= gfortran/= verificarlo/g' make.inc &&\
    sed -i 's/-frecursive/-fPIC -frecursive/g' make.inc &&\
    cd /opt/build/lapack-3.5.0/BLAS/SRC/ &&\
    make &&\
    cd /opt/build/lapack-3.5.0/ &&\
    cmake . && make &&\
    cp lib/* /usr/local/lib/

# Build numpy from sources and link with the local BLAS and LAPACK
COPY numpy-site.cfg /root/.numpy-site.cfg
RUN pip3.6 install cython
RUN pip3.6 install --no-binary :all: numpy

# Restore default behavior for verificarlo's CC
ENV CC "verificarlo"
ENV VERIFICARLO_MCAMODE "MCA"
ENV VERIFICARLO_BACKEND "QUAD"

ENTRYPOINT [ "/bin/bash"]
