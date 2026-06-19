FROM ubuntu:24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl jq ca-certificates zstd \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://ollama.com/install.sh | sh \
    && ollama --version

COPY prompt.txt /app/prompt.txt
COPY generate-site.sh /app/generate-site.sh

RUN chmod +x /app/generate-site.sh

ENTRYPOINT ["/app/generate-site.sh"]
