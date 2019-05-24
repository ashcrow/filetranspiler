FROM registry.fedoraproject.org/fedora:latest

COPY nettranspile /usr/bin/nettranspile

RUN dnf update -y && \
    chmod a+x /usr/bin/nettranspile

WORKDIR /srv
ENTRYPOINT ["/usr/bin/nettranspile"]
