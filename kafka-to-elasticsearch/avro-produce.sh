docker cp mock-data.json schema-registry:/mock-data.json

docker exec schema-registry bash -c \
'kafka-avro-console-producer \
--bootstrap-server broker:9092 \
--topic my-topic \
--property schema.registry.url=http://localhost:8081 \
--property value.schema.id=1 < /mock-data.json'