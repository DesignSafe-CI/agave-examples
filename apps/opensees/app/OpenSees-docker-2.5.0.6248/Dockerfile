######################################################
#
# OpenSees image
# Tag: stevemock/docker-opensees
#
# This is a vanilla installation of OpenSees 2.5.0 on Ubuntu 12.04.
# You can run the app demo by running the container with no
# arguments.
#
# docker run -it --rm stevemock/docker-opensees
#
# To run your own input, mount your data to the /data volume and
# specify the traditional invocation command
#
# docker run -it --rm -v `pwd`:/data stevemock/docker-opensees /bin/sh -c 'OpenSees < /data/myinput.tcl'
#
# The data will appear in your current directory at the end of the run.
#
######################################################

FROM ubuntu:12.04
MAINTAINER Stephen Mock <mock@tacc.utexas.edu>
RUN apt-get -y update && \
    apt-get -y install subversion emacs make tcl8.5 tcl8.5-dev gcc g++ gfortran && \
    useradd --create-home ubuntu && \
    cd /home/ubuntu && \
    mkdir bin lib && \
    svn co svn://opensees.berkeley.edu/usr/local/svn/OpenSees/trunk@6228 OpenSees && \
    cd OpenSees && \
    cp MAKES/Makefile.def.EC2-UBUNTU Makefile.def && \
    make

COPY inputs /data
RUN chown -R ubuntu:ubuntu /home/ubuntu /data
USER ubuntu
WORKDIR /data
ENV PATH $PATH:/home/ubuntu/bin

VOLUME ["/data"]
CMD [ "/bin/sh", "-c", "OpenSees < /data/SimpleCyclicShear/1elem_woutput_debug.tcl" ]
