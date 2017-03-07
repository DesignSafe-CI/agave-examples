# Dockerfile for OpenSees on Ubuntu

This is a vanilla installation of OpenSees on Ubuntu 12.04.
You can run the app demo by running the container with no
arguments.

> docker run -it --rm stevemock/docker-opensees

To run your own input, mount your data to the `/data` volume and
specify the traditional invocation command. In the following example,
a file in the current directory named `myinput` is passed into OpenSees.

> docker run -it --rm -v `pwd`:/data stevemock/docker-opensees /bin/sh -c 'OpenSees < /data/myinput.tcl'


After OpenSees completes running, all output data will appear in your
current directory.
