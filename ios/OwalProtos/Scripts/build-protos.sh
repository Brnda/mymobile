#!/bin/bash

# Assuming we're in (something)/owal-mobile/ios/OwalProtos/...
# and protos are in (something)/owal/src/protobuf/...
PROTOS_DIR=${SRCROOT}/../../../owal/src/protobuf/
pwd

mkdir -p protos
protoc --objc_out=protos --proto_path=${PROTOS_DIR} ${PROTOS_DIR}/*.proto
