FROM verificarlo/verificarlo:latest

RUN apt-get update -qqq &&\
    apt-get install -y -qqq make build-essential libssl-dev zlib1g-dev \
                            libbz2-dev libreadline-dev libsqlite3-dev wget \
                            curl llvm libncurses5-dev  libncursesw5-dev \
                            xz-utils tk-dev wget fort77 gfortran &&\
    rm -rf /var/lib/apt/lists/

# Copying the patched version which does an fPIC compilation instead of static
COPY verificarlo /usr/local/bin/verificarlo

ENV CC "verificarlo"
ENV FC "verificarlo"
ENV LD "verificarlo"
ENV LDSHARED "verificarlo -shared"

# Replace IEEE with MCA and MPFR with QUAD after build
ENV VERIFICARLO_MCAMODE "IEEE"
ENV VERIFICARLO_PRECISION "53"
ENV VERIFICARLO_BACKEND "MPFR"

# Build BLAS from following URL's instructions:
#  http://ab-initio.mit.edu/wiki/index.php/Template:Installing_BLAS_and_LAPACK
RUN mkdir -p /opt/build/ &&\
    cd /opt/build/ &&\
    wget http://www.netlib.org/blas/blas-3.8.0.tgz &&\
    gunzip blas-3.8.0.tgz &&\
    tar -xf blas-3.8.0.tar &&\
    cd /opt/build/BLAS-3.8.0/ &&\
    make

RUN cd /opt/build/ &&\
    wget http://www.netlib.org/lapack/lapack-3.5.0.tgz &&\
    gunzip lapack-3.5.0.tgz &&\
    tar xf lapack-3.5.0.tar &&\
    cd /opt/build/lapack-3.5.0/ &&\
    cp make.inc.example make.inc &&\
    cd /opt/build/lapack-3.5.0/BLAS/SRC/ &&\
    make &&\
    cd /opt/build/lapack-3.5.0/ &&\
    make

# 
# # TODO: replace the f77 command w/ verificarlo
# 
# # RUN mkdir -p /opt/build/ && \
# #     cd /opt/build/ && \
# #     wget https://www.python.org/ftp/python/3.6.5/Python-3.6.5.tgz && \
# #     tar xvf Python-3.6.5.tgz && \
# #     cd Python-3.6.5 && \
# #     ./configure --enable-optimizations --with-ensurepip=install
# 
# RUN cd /opt/build/Python-3.6.5 && \
#     make
# 
# ENV VERIFICARLO_MCAMODE "MCA"
# ENV VERIFICARLO_BACKEND "QUAD"
# 
ENTRYPOINT [ "/bin/bash"]