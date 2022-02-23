jq '.' es-sink-connector.json | \
curl -i -X PUT -H  "Content-Type:application/json" \
http://localhost:8083/connectors/es-sink-connector-00/config \
-d @- 