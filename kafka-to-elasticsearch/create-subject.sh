jq '. | {schema: tojson}' record-schema.json | \
curl -X POST http://localhost:8081/subjects/my-topic-value/versions \
-H "Content-Type:application/json" -d @-