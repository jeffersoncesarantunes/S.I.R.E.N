FROM alpine:3.20
RUN apk add --no-cache bash python3 coreutils file findutils
WORKDIR /siren
COPY src/ src/
COPY lib/ lib/
COPY tools/ tools/
ENTRYPOINT ["bash", "src/siren.sh"]
