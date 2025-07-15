FROM alpine:3.22.1

RUN apk -Uuv add bash ca-certificates git curl jq openssh
RUN mkdir -p /root/.ssh

COPY src/run.sh /bin/

ENTRYPOINT ["/bin/run.sh"]
