FROM registry.fedoraproject.org/fedora:latest

COPY filetranspile /usr/bin/filetranspile

RUN dnf update -y && \
    chmod a+x /usr/bin/filetranspile

WORKDIR /srv
ENTRYPOINT ["/usr/bin/filetranspile"]
