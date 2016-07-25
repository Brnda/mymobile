package io.owal.android;

import owal.*;

public class ProtoWrapper {

  private static final byte[] Authorizer = {(byte)0xDE, (byte)0xAD, (byte)0xBE, (byte)0xEF};

  ProtoWrapper() {
    CameraRequest request = new CameraRequest();
    request.authorizer.uuid = Authorizer;
  }
}
