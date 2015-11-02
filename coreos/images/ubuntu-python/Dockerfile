FROM hklement/ubuntu-python
RUN apt-get update && apt-get install -y python3-pip python-pip
RUN pip install requests

WORKDIR /

COPY download.py /download.py
COPY execute.sh /execute.sh
