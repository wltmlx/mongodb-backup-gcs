FROM mongo:8

LABEL maintainer="wltmlx" \
      description="MongoDB backup solution for Google Cloud Storage" \
      version="1.0.0"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cron \
      python3-pip && \
    pip3 install --no-cache-dir gsutil && \
    rm -rf /var/lib/apt/lists/*

ENV CRON_TIME="0 3 * * *" \
    TZ=UTC \
    CRON_TZ=UTC

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
