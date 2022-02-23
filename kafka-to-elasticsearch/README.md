# Kafka to Elasticsearch

This example demonstrates how to send the topic from Kafka into Elasticsearch.

[Confluent Hub](https://www.confluent.io/hub/)

[Elasticsearch Sink Connector](https://www.confluent.io/hub/confluentinc/kafka-connect-elasticsearch)

Spin up the containers:

```bash
docker-compose up -d
```

List the containers:

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
schema-registry   /etc/confluent/docker/run        Up             0.0.0.0:8081->8081/tcp
zookeeper         /etc/confluent/docker/run        Up             0.0.0.0:2181->2181/tcp, 2888/tcp, 3888/tcp
```

We check the available connector plugins first:

```bash
curl -s http://localhost:8083/connector-plugins | jq '.[].class'
```

Expected output:

```bash
"io.confluent.connect.elasticsearch.ElasticsearchSinkConnector"
"org.apache.kafka.connect.mirror.MirrorCheckpointConnector"
"org.apache.kafka.connect.mirror.MirrorHeartbeatConnector"
"org.apache.kafka.connect.mirror.MirrorSourceConnector"
```

Create a new subject:

```bash
bash create-subject.sh
```

To list the subject, run

```bash
curl -s http://localhost:8081/subjects/my-topic-value/versions/1 | jq
```

Expected output:

```json
{
  "subject": "my-topic-value",
  "version": 1,
  "id": 1,
  "schema": "{\"type\":\"record\",\"name\":\"MockData\",\"namespace\":\"kafka-demo\",\"fields\":[{\"name\":\"id\",\"type\":\"long\",\"doc\":\"The id\"},{\"name\":\"first_name\",\"type\":\"string\",\"doc\":\"The first name.\"},{\"name\":\"last_name\",\"type\":\"string\",\"doc\":\"The last name.\"},{\"name\":\"age\",\"type\":\"long\",\"doc\":\"The age.\"},{\"name\":\"email\",\"type\":\"string\",\"doc\":\"The email.\"},{\"name\":\"gender\",\"type\":\"string\",\"doc\":\"The gender.\"},{\"name\":\"ip_address\",\"type\":\"string\",\"doc\":\"The ip address.\"},{\"name\":\"score\",\"type\":\"double\",\"doc\":\"The score.\"}]}"
}
```

Another way is to run:

```bash
curl -s http://localhost:8081/schemas | jq '.[]'
```

Next produce some messages into the topic `my-topic`:

```bash
bash avro-produce.sh
```

We can verify there are indeed messages inside the topic `my-topic` by running:

```bash
bash avro-consume.sh
```

Let's create the Elasticsearch sink connector.

Before creating the connector, we can check the currently available connectors first:

```bash
curl localhost:8083/connectors
```

Expected output:

```bash
[]
```

To create the Elasticsearch sink connector, we run:

```bash
bash create-es-sink-connector.sh
```

Expected output:

```bash
HTTP/1.1 201 Created
Date: Wed, 23 Feb 2022 17:13:30 GMT
Location: http://localhost:8083/connectors/es-sink-connector-00
Content-Type: application/json
Content-Length: 324
Server: Jetty(9.4.43.v20210629)

{"name":"es-sink-connector-00","config":{"connector.class":"io.confluent.connect.elasticsearch.ElasticsearchSinkConnector","topics":"my-topic","connection.url":"http://elasticsearch:9200","type.name":"type.name=kafkaconnect","key.ignore":"true","schema.ignore":"true","name":"es-sink-connector-00"},"tasks":[],"type":"sink"}
```

Verify the sink connector is created successfully:

```bash
curl -s http://localhost:8083/connectors/es-sink-connector-00 | jq
```

Expected output:

```json
{
  "name": "es-sink-connector-00",
  "config": {
    "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
    "type.name": "type.name=kafkaconnect",
    "topics": "my-topic",
    "name": "es-sink-connector-00",
    "connection.url": "http://elasticsearch:9200",
    "key.ignore": "true",
    "schema.ignore": "true"
  },
  "tasks": [
    {
      "connector": "es-sink-connector-00",
      "task": 0
    }
  ],
  "type": "sink"
}
```

To verify that there exists the index `my-topic` in Elasticsearch, we can make the following request in the terminal:

```bash
curl localhost:9200/my-topic/_count
```

Expected output:

```bash
{"count":30,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0}}
```

Another way is to go to http://localhost:5601/app/dev_tools#/console and execute the query:

```json
GET my-topic/_count
```

Expected output:

```json
{
  "count": 30,
  "_shards": {
    "total": 1,
    "successful": 1,
    "skipped": 0,
    "failed": 0
  }
}
```

We can produce more messages by running `bash avro-produce.sh` again, and observe the number of documents of the index `my-topic` increases.

Finally, tear down the containers:

```bash
docker-compose down
```
