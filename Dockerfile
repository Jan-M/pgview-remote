FROM alpine:3.5
MAINTAINER team-acid@zalando.de

EXPOSE 8080

RUN apk add --no-cache python3 python3-dev gcc musl-dev zlib-dev libffi-dev openssl-dev ca-certificates && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools gevent && \
    apk del python3-dev gcc musl-dev zlib-dev libffi-dev openssl-dev && \
    rm -rf /var/cache/apk/* /root/.cache /tmp/* 

COPY scm-source.json /

COPY requirements.txt /
RUN pip3 install -r /requirements.txt

COPY pgview-web /pgview-web

ARG VERSION=dev
RUN sed -i "s/__version__ = .*/__version__ = '${VERSION}'/" /pgview-web/__init__.py

WORKDIR /
ENTRYPOINT ["/usr/bin/python3", "-m", "pgview-web"]
