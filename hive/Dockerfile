FROM apache/hive:3.1.3

USER root

RUN apt-get update && \
    apt-get install -y \
    curl \
    gettext-base && \
    rm -rf /var/lib/apt/lists/*

# PostgreSQL JDBC
RUN curl -L \
    -o /opt/hive/lib/postgresql-42.7.3.jar \
    https://jdbc.postgresql.org/download/postgresql-42.7.3.jar

# Hadoop AWS
RUN curl -L \
    -o /opt/hive/lib/hadoop-aws-3.1.2.jar \
    https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.1.2/hadoop-aws-3.1.2.jar

# AWS SDK
RUN curl -L \
    -o /opt/hive/lib/aws-java-sdk-bundle-1.11.375.jar \
    https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.375/aws-java-sdk-bundle-1.11.375.jar

COPY conf/hive-site.xml.template /opt/hive/conf/

COPY entrypoint.sh /entrypoint-custom.sh
RUN chmod +x /entrypoint-custom.sh

ENTRYPOINT ["/entrypoint-custom.sh"]