docker exec schema-registry bash -c \
'kafka-avro-console-consumer \
--bootstrap-server broker:9092 \
--topic my-topic \
--property schema.registry.url=http://localhost:8081 \
--property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer \
--property print.key=true \
--property key.separator="-" \
--from-beginning'