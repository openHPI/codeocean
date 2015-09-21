FROM ubuntu:14.04
MAINTAINER "Martin v. Löwis"
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ADD assess.py /usr/lib/python3.4/assess.py
ADD webpython.py /usr/lib/python3.4/webpython.py
RUN rm /usr/lib/python3.4/turtle.py
ADD turtle.py /usr/lib/python3.4/turtle.py
RUN adduser --disabled-password --gecos Python python
USER python
WORKDIR /usr/lib/python3.4
