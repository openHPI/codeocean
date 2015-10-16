FROM ubuntu:14.04
MAINTAINER "Martin v. Löwis"
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV PYTHONPATH $PYTHONPATH:/usr/lib/python3.4:/workspace
ENV PATH $PATH:/usr/lib/python3.4
ADD assess.py /usr/lib/python3.4/assess.py
ADD webpython.py /usr/lib/python3.4/webpython.py
RUN rm /usr/lib/python3.4/turtle.py
ADD turtle.py /usr/lib/python3.4/turtle.py
RUN adduser --disabled-password --gecos Python python
USER python