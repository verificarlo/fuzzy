FROM verificarlo/verificarlo:latest

RUN apt-get update -qqq &&\
    apt-get install -y -qqq python3-dev python3-pip

RUN pip3 install cython

# Copying the patched version which does an fPIC compilation instead of static
COPY verificarlo /usr/local/bin/verificarlo

ENV CC "verificarlo"
ENV FC "verificarlo"
ENV LDSHARED "verificarlo -shared"

ENV VERIFICARLO_MCAMODE "MCA"
ENV VERIFICARLO_PRECISION "53"
ENV VERIFICARLO_BACKEND "QUAD"

ENTRYPOINT [ "/bin/bash"]