FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl ca-certificates bash \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/ducminh11102012/workspace/raw/refs/heads/main/setup.sh | bash

CMD ["bash", "/start.sh"]
