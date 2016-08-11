//
//  ProtoWrapper.m
//  owalMobile
//
//  Created by Yakov Okshtein on 7/21/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "ProtoWrapper.h"
#import "OwalProtos.h"

@implementation ProtoWrapper

- (id)init {
  self = [super init];
  if (self) {
    CameraListRequest *request = [CameraListRequest message];
    request = nil;
  }
  return self;
}

@end
