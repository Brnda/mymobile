package io.owal.android;

import owal.*;

public class ProtoWrapper {

  private static final String Authorizer = "SAMPLE_AUTHORIZER";

  ProtoWrapper() {
    CameraListRequest cameraListRequest = new CameraListRequest();
    cameraListRequest.authorizer.id.uuid = Authorizer;
  }
}
