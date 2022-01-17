[Confluent Hub](https://www.confluent.io/hub)

[Kafka Connect File Pulse](https://github.com/streamthoughts/kafka-connect-file-pulse)

Spin up the stack:

```bash
docker-compose up -d
```

In the terminal, run:

```bash
curl -s http://localhost:8083/connector-plugins | jq '.[].class'
```

would see something like this:

```bash
"io.streamthoughts.kafka.connect.filepulse.source.FilePulseSourceConnector"
"org.apache.kafka.connect.mirror.MirrorCheckpointConnector"
"org.apache.kafka.connect.mirror.MirrorHeartbeatConnector"
"org.apache.kafka.connect.mirror.MirrorSourceConnector"
```

Create the connector:

```bash
curl -sX PUT http://localhost:8083/connectors/csv-source-connector/config \
-d @csv-source-connector.json \
--header "Content-Type: application/json" | jq
```

Check the connector:

```bash
curl -s http://localhost:8083/connectors/csv-source-connector | jq
```

List the topics:

```bash
docker exec broker bash -c \
'kafka-topics --bootstrap-server broker:9092 --list'
```

We should see there does exist the topic `csv-source-connector`, which is defined in the `csv-source-connector.json`.

Consume messages:

```bash
docker exec -it schema-registry \
bash -c 'kafka-avro-console-consumer \
--topic csv-source-connector \
--from-beginning \
--bootstrap-server broker:9092 \
--property schema.registry.url=http://schema-registry:8081'
```

Expected output:

```bash
{"age":{"string":"10"},"name":{"string":"alex"},"score":{"string":"10.1"}}
{"age":{"string":"30"},"name":{"string":"joe"},"score":{"string":"30.3"}}
{"age":{"string":"40"},"name":{"string":"mark"},"score":{"string":"40.4"}}
```

Enter into ksqldb:

```bash
docker exec -it ksqldb ksql http://localhost:8088
```

Show topics:

```sql
show topics;
```

Expected output:

```sql

 Kafka Topic                     | Partitions | Partition Replicas
-------------------------------------------------------------------
 connect-file-pulse-status       | 10         | 1
 csv-source-connector            | 1          | 1
 kafka_ksqldbksql_processing_log | 1          | 1
-------------------------------------------------------------------
```

Print the topic:

```sql
print 'csv-source-connector' from beginning;
```

Expected output:

```sql
Key format: ¯\_(ツ)_/¯ - no data processed
Value format: AVRO or KAFKA_STRING
rowtime: 2022/01/08 19:30:38.111 Z, key: <null>, value: {"age": "10", "name": "alex", "score": "10.1"}, partition: 0
rowtime: 2022/01/08 19:30:38.111 Z, key: <null>, value: {"age": "30", "name": "joe", "score": "30.3"}, partition: 0
rowtime: 2022/01/08 19:30:39.031 Z, key: <null>, value: {"age": "40", "name": "mark", "score": "40.4"}, partition: 0
```

To debug, run:

```bash
kafka-console-consumer \
--bootstrap-server broker:9092 \
--topic connect-file-pulse-status \
--from-beginning
```

Tear down the stack:

```bash
docker-compose down
```
