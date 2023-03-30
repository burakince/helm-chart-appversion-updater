FROM alpine:3.17.3

RUN apk -Uuv add bash ca-certificates git curl jq openssh
RUN mkdir -p /root/.ssh

COPY run.sh /bin/

ENTRYPOINT /bin/run.sh
