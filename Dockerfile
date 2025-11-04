FROM mongo:8

LABEL maintainer="wltmlx" \
      description="MongoDB backup solution for Google Cloud Storage" \
      version="1.0.0"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cron \
      curl \
      gnupg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-cloud-sdk && \
    rm -rf /var/lib/apt/lists/*

ENV CRON_TIME="0 3 * * *" \
    TZ=UTC \
    CRON_TZ=UTC

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
