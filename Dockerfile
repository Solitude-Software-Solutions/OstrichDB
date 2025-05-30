FROM golang:1.23.1 as builder

RUN apt-get update && apt-get install -y \
    build-essential \
    clang \
    llvm-14 \
    llvm-14-dev \
    git \
    curl \
    libssl-dev \
    libffi-dev \
    libtool \
    automake \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/odin-lang/Odin.git /Odin \
    && cd /Odin \
    && git checkout dev-2024-11 \
    && git reset --hard 764c32fd3 \
    && make release-native

ENV PATH="/Odin:$PATH"

RUN git clone https://github.com/Archetype-Dynamics/OstrichDB-CLI.git /OstrichDB \
    && cd /OstrichDB \
    && chmod +x scripts/local_build_run.sh \
    && ./scripts/local_build_run.sh

FROM golang:1.23.1
WORKDIR /data
COPY --from=builder /OstrichDB/bin/main.bin /app/main.bin
COPY --from=builder /OstrichDB/bin/nlp.so /OstrichDB/src/core/nlp/nlp.so
