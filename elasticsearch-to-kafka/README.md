# Elasticsearch to Kafka using Kafka-Connect

Set up the containers:

```bash
docker-compose up -d
```

```bash
docker-compose ps
```

Expected output:

```bash
     Name                    Command                  State                         Ports
------------------------------------------------------------------------------------------------------------
broker            /etc/confluent/docker/run        Up             0.0.0.0:29092->29092/tcp, 9092/tcp
elasticsearch     /bin/tini -- /usr/local/bi ...   Up             0.0.0.0:9200->9200/tcp, 9300/tcp
kafka-connect     bash -c confluent-hub inst ...   Up (healthy)   0.0.0.0:8083->8083/tcp, 9092/tcp
kibana            /bin/tini -- /usr/local/bi ...   Up             0.0.0.0:5601->5601/tcp
ksqldb            /etc/confluent/docker/run        Up             0.0.0.0:8088->8088/tcp
schema-registry   /etc/confluent/docker/run        Up             0.0.0.0:8081->8081/tcp
zookeeper         /etc/confluent/docker/run        Up             0.0.0.0:2181->2181/tcp, 2888/tcp, 3888/tcp
```

And the Elasticsearch container should be ready now:

```bash
curl http://localhost:9200
```

Expected output:

```json
{
  "name": "elasticsearch",
  "cluster_name": "docker-cluster",
  "cluster_uuid": "G5dNmUtNRzqkFX2AT_YXmA",
  "version": {
    "number": "7.14.0",
    "build_flavor": "default",
    "build_type": "docker",
    "build_hash": "dd5a0a2acaa2045ff9624f3729fc8a6f40835aa1",
    "build_date": "2021-07-29T20:49:32.864135063Z",
    "build_snapshot": false,
    "lucene_version": "8.9.0",
    "minimum_wire_compatibility_version": "6.8.0",
    "minimum_index_compatibility_version": "6.0.0-beta1"
  },
  "tagline": "You Know, for Search"
}
```

List the connector plugins:

```bash
curl -s http://localhost:8083/connector-plugins | jq '.[].class'
```

Expected output should be:

```json
"com.github.dariobalinzo.ElasticSourceConnector"
"org.apache.kafka.connect.mirror.MirrorCheckpointConnector"
"org.apache.kafka.connect.mirror.MirrorHeartbeatConnector"
"org.apache.kafka.connect.mirror.MirrorSourceConnector"
```

Post the index called `mock-index`:

```bash
curl -XPOST \
"http://localhost:9200/mock-index/_bulk" \
-H 'Content-Type: application/json' \
--data-binary "@samples.json"
```

Get the index `mock-index`:

```bash
curl -s http://localhost:9200/mock-index/_search | jq -c '.hits.hits[]._source'
```

Expected output:

```json
{"name":"alex","@timestamp":"2022-01-01T10:00:00Z","score":11.1,"email":"alex@gmail.com"}
{"name":"bob","@timestamp":"2022-01-01T10:01:00Z","score":22.2,"email":"bob@gmail.com"}
{"name":"joe","@timestamp":"2022-01-01T10:02:00Z","score":33.3,"email":"joe@gmail.com"}
{"name":"mark","@timestamp":"2022-01-01T10:03:00Z","score":44.4,"email":"mark@gmail.com"}
```

Go to http://localhost:5601/app/dev_tools#/console and query the index:

```json
GET mock-index/_count
```

Expected output:

```json
{
  "count": 4,
  "_shards": {
    "total": 1,
    "successful": 1,
    "skipped": 0,
    "failed": 0
  }
}
```

Create the Elasticsearch source connector:

```bash
curl -iX PUT http://localhost:8083/connectors/es_source_connector/config \
-H "Content-Type: application/json" \
-H "Accept:application/json" \
-d @es_source_connector_00.json
```

Expected output:

```bash
HTTP/1.1 201 Created
Date: Fri, 17 Dec 2021 10:51:52 GMT
Location: http://localhost:8083/connectors/es_source_connector
Content-Type: application/json
Content-Length: 361
Server: Jetty(9.4.43.v20210629)

{"name":"es_source_connector","config":{"connector.class":"com.github.dariobalinzo.ElasticSourceConnector","topic.prefix":"es_","task.max":"1","poll.interval.ms":"3000","es.host":"localhost","es.port":"9200","incrementing.field.name":"@timestamp","index.prefix":"mock-index","fieldname_converter":"avro","name":"es_source_connector"},"tasks":[],"type":"source"}
```

Check the schema:

```bash
curl -s localhost:8081/schemas | jq
```

Expected output:

```json
[
  {
    "subject": "es_mock-index-value",
    "version": 1,
    "id": 1,
    "schema": "{\"type\":\"record\",\"name\":\"mockindex\",\"fields\":[{\"name\":\"score\",\"type\":[\"null\",\"double\"],\"default\":null},{\"name\":\"avrotimestamp\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"name\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"email\",\"type\":[\"null\",\"string\"],\"default\":null}],\"connect.name\":\"mockindex\"}"
  }
]
```

List the subject:

```bash
curl -s localhost:8081/subjects/es_mock-index-value/versions/latest | jq
```

Expected output:

```json
{
  "subject": "es_mock-index-value",
  "version": 1,
  "id": 1,
  "schema": "{\"type\":\"record\",\"name\":\"mockindex\",\"fields\":[{\"name\":\"score\",\"type\":[\"null\",\"double\"],\"default\":null},{\"name\":\"avrotimestamp\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"name\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"email\",\"type\":[\"null\",\"string\"],\"default\":null}],\"connect.name\":\"mockindex\"}"
}
```

List the connectors:

```bash
curl -s 'localhost:8083/connectors?expand=status&expand=info' | jq
```

Expected output:

```json
{
  "es_source_connector": {
    "status": {
      "name": "es_source_connector",
      "connector": {
        "state": "RUNNING",
        "worker_id": "kafka-connect:8083"
      },
      "tasks": [
        {
          "id": 0,
          "state": "RUNNING",
          "worker_id": "kafka-connect:8083"
        }
      ],
      "type": "source"
    },
    "info": {
      "name": "es_source_connector",
      "config": {
        "connector.class": "com.github.dariobalinzo.ElasticSourceConnector",
        "topic.prefix": "es_",
        "fieldname_converter": "avro",
        "es.host": "elasticsearch",
        "task.max": "1",
        "poll.interval.ms": "3000",
        "incrementing.field.name": "@timestamp",
        "name": "es_source_connector",
        "es.port": "9200",
        "index.prefix": "mock-index"
      },
      "tasks": [
        {
          "connector": "es_source_connector",
          "task": 0
        }
      ],
      "type": "source"
    }
  }
}
```

List the topics:

```bash
docker exec broker bash -c 'kafka-topics \
--bootstrap-server broker:9092 \
--list'
```

Expected output:

```bash
__consumer_offsets
__transaction_state
_confluent-ksql-kafka_ksqldb_command_topic
_connect-configs
_connect-offsets
_connect-status
_schemas
es_mock-index
kafka_ksqldbksql_processing_log
```

Consume the messages:

```bash
docker exec schema-registry bash -c \
'kafka-avro-console-consumer \
--bootstrap-server broker:9092 \
--topic es_mock-index \
--property schema.registry.url=http://localhost:8081 \
--property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer \
--property value.deserializer=io.confluent.connect.avro.AvroConverter \
--property key.separator="-" \
--property print.key=true \
--from-beginning'
```

Expected output:

```bash
mock-index_2022-01-01T10:00:00Z-{"score":{"double":11.1},"avrotimestamp":{"string":"2022-01-01T10:00:00Z"},"name":{"string":"alex"},"email":{"string":"alex@gmail.com"}}
mock-index_2022-01-01T10:01:00Z-{"score":{"double":22.2},"avrotimestamp":{"string":"2022-01-01T10:01:00Z"},"name":{"string":"bob"},"email":{"string":"bob@gmail.com"}}
mock-index_2022-01-01T10:02:00Z-{"score":{"double":33.3},"avrotimestamp":{"string":"2022-01-01T10:02:00Z"},"name":{"string":"joe"},"email":{"string":"joe@gmail.com"}}
mock-index_2022-01-01T10:03:00Z-{"score":{"double":44.4},"avrotimestamp":{"string":"2022-01-01T10:03:00Z"},"name":{"string":"mark"},"email":{"string":"mark@gmail.com"}}
```

Enter into the ksqldb:

```bash
docker exec -it ksqldb ksql http://localhost:8088
```

```sql
show connectors;
```

Expected output:

```bash
 Connector Name      | Type   | Class                                          | Status
-------------------------------------------------------------------------------------------------------------
 es_source_connector | SOURCE | com.github.dariobalinzo.ElasticSourceConnector | RUNNING (1/1 tasks RUNNING)
-------------------------------------------------------------------------------------------------------------
```

```sql
describe connector "es_source_connector";
```

Expected output:

```bash
Name                 : es_source_connector
Class                : com.github.dariobalinzo.ElasticSourceConnector
Type                 : source
State                : RUNNING
WorkerId             : kafka-connect:8083

 Task ID | State   | Error Trace
---------------------------------
 0       | RUNNING |
---------------------------------
```

```sql
show topics;
```

Expected output:

```bash
 Kafka Topic                     | Partitions | Partition Replicas
-------------------------------------------------------------------
 es_mock-index                   | 1          | 1
 kafka_ksqldbksql_processing_log | 1          | 1
-------------------------------------------------------------------
```

```sql
set 'auto.offset.reset' = 'earliest';
```

Expected output:

```bash
Successfully changed local property 'auto.offset.reset' to 'earliest'. Use the UNSET command to revert your change.
```

```sql
print 'es_mock-index';
```

Expected output:

```bash
Key format: HOPPING(KAFKA_STRING) or TUMBLING(KAFKA_STRING) or KAFKA_STRING
Value format: AVRO
rowtime: 2022/01/18 07:14:25.087 Z, key: [mock-index_2022-01-01T1@3475143046162559066/-], value: {"score": 11.1, "avrotimestamp": "2022-01-01T10:00:00Z", "name": "alex", "email": "alex@gmail.com"}, partition: 0
rowtime: 2022/01/18 07:14:25.089 Z, key: [mock-index_2022-01-01T1@3475143050457526362/-], value: {"score": 22.2, "avrotimestamp": "2022-01-01T10:01:00Z", "name": "bob", "email": "bob@gmail.com"}, partition: 0
rowtime: 2022/01/18 07:14:25.089 Z, key: [mock-index_2022-01-01T1@3475143054752493658/-], value: {"score": 33.3, "avrotimestamp": "2022-01-01T10:02:00Z", "name": "joe", "email": "joe@gmail.com"}, partition: 0
rowtime: 2022/01/18 07:14:25.089 Z, key: [mock-index_2022-01-01T1@3475143059047460954/-], value: {"score": 44.4, "avrotimestamp": "2022-01-01T10:03:00Z", "name": "mark", "email": "mark@gmail.com"}, partition: 0
```

Tear down the stack:

```bash
docker-compose down
```
