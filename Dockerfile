FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        python3 \
        perl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN make clean && make \
    && sed 's/127\.0\.0\.1/0.0.0.0/g' config/default.conf > config/docker.conf

EXPOSE 8080 9090

STOPSIGNAL SIGTERM

CMD ["./webserv", "config/docker.conf"]
