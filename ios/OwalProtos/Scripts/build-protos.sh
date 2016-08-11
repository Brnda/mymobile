#!/bin/bash

# Assuming we're in (something)/owal-mobile/ios/OwalProtos/...
# and protos are in (something)/owal/src/proto/...
# but their "root" dir is (something)/owal/src/...
PROTOS_DIR=${SRCROOT}/../../../owal/src/
mkdir -p protos
../../bin/protoc --objc_out=protos --proto_path=${PROTOS_DIR} ${PROTOS_DIR%/}/proto/*.proto

for f in `ls protos/proto/*.h`; do echo "#import" \"${f##protos/}\"; done > ${SRCROOT}/OwalProtos/OwalProtos.h
