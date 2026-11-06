kubectl port-forward -n gen3 svc/gen3-elasticsearch-master 9200:9200 &
sleep 2
for IDX in predict_test predict_test-array-config; do
  jq --arg i $IDX '.[$i] | {
      settings: {index: (.settings.index | del(.uuid,.creation_date,.provided_name,.version) | .number_of_replicas="0")},
      mappings: .mappings }' old/${IDX}_index.json > ${IDX}_create.json
  curl -s -XPUT localhost:9200/$IDX -H 'Content-Type: application/json' -d @${IDX}_create.json; echo
  curl -s -XPOST "localhost:9200/$IDX/_bulk?refresh=true" -H 'Content-Type: application/x-ndjson' \
       --data-binary @${IDX}_bulk.ndjson | jq '{errors, items: (.items|length)}'
done

curl -s localhost:9200/predict_test/_count                 # expect 1280
curl -s localhost:9200/predict_test-array-config/_count    # expect 1

pkill -f "port-forward.*elasticsearch"
