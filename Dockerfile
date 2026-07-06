FROM python:3.6
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive TERM=linux

EXPOSE 8801

RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates

RUN pip3 install pipenv

RUN git clone -b master https://github.com/airnotifier/airnotifier.git /airnotifier   # was -b 2.x
COPY config.py /airnotifier/config.py
RUN mkdir -p /var/airnotifier/pemdir && \
    mkdir -p /var/log/airnotifier
VOLUME ["/airnotifier", "/var/log/airnotifier", "/var/airnotifier/pemdir"]
WORKDIR /airnotifier

RUN pipenv install --deploy

ADD start.sh /airnotifier
RUN chmod a+x /airnotifier/start.sh
ENTRYPOINT /airnotifier/start.sh
