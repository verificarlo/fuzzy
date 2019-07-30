FROM verificarlo/verificarlo:latest

RUN apt-get update -qqq &&\
    apt-get install -y -qqq python3-dev python3-pip

RUN pip3 install cython

ENV CC verificarlo
ENV FC verificarlo
ENV LD verificarlo

ENV VERIFICARLO_MCAMODE MCA
ENV VERIFICARLO_PRECISION 53
ENV VERIFICARLO_BACKEND MPFR


ENTRYPOINT [ "/bin/bash"]