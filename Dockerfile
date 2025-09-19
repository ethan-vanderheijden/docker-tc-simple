FROM debian:trixie-slim

RUN apt-get update && apt-get install -y \
    curl \
    iproute2 \
    jq \
    && rm -rf /var/lib/apt/lists/*

ARG DOCKER_VERSION=""
RUN ( curl -fsSL get.docker.com | VERSION=${DOCKER_VERSION} CHANNEL=stable sh ) && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

COPY ./bin /docker-tc
RUN chmod +x /docker-tc/*

LABEL com.docker-tc.enabled=0 \
      com.docker-tc.self=1

ENTRYPOINT ["/docker-tc/docker-tc.sh"]
