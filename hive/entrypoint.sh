#!/bin/bash
set -e

echo "Gerando hive-site.xml..."

envsubst < /opt/hive/conf/hive-site.xml.template \
         > /opt/hive/conf/hive-site.xml

echo "Hive configuration:"
cat /opt/hive/conf/hive-site.xml

echo "Verificando schema Hive..."

if /opt/hive/bin/schematool \
      -dbType postgres \
      -info; then

    echo "Schema já existe."

else

    echo "Criando schema..."

    /opt/hive/bin/schematool \
      -dbType postgres \
      -initSchema
fi

echo "Iniciando Hive Metastore..."

exec /opt/hive/bin/hive \
    --service metastore