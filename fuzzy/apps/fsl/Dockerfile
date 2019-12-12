FROM gkiar/fuzzy:ubuntu14.04-libmath

RUN apt-get update && apt install -y wget

ADD neurodebian-travis.sh /tmp
RUN bash /tmp/neurodebian-travis.sh
RUN apt install -y fsl