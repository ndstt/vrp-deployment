#!/bin/bash
# create kafka-ui container using podman
sudo podman run -d \
  --network=host \
  --name kafka-ui \
  -e DYNAMIC_CONFIG_ENABLED=true \
  -e KAFKA_CLUSTERS_0_NAME=local \
  -e KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=localhost:9092 \
  docker.io/provectuslabs/kafka-ui:latest

# to start the kafka-ui container if it's not running
#sudo podman start kafka-ui