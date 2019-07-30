FROM verificarlo/verificarlo:latest

RUN apt-get update -qqq &&\
    apt-get install -y -qqq python3-dev python3-pip

RUN pip3 install cython

ENTRYPOINT [ "/bin/bash" ]