FROM trinodb/trino:476

USER root

RUN mkdir -p /var/trino/data && \
    chown -R trino:trino /var/trino

USER trino