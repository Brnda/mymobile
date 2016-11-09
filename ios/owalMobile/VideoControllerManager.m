//
//  VideoController.m
//  owalMobile
//
//  Created by Mateo Barraza on 10/11/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "VideoControllerManager.h"
#import "VideoControllerView.h"

@implementation VideoControllerManager

static NSString* _uri = @"";

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(setURI:(NSString* )uri) {
  NSLog(@"got uri %@", uri);
  _uri = uri;
}

- (UIView *)view
{  
  VideoControllerView *viewz = [[VideoControllerView alloc] initWithURLString:_uri decoderOptions:[NSDictionary dictionaryWithObject:VKDECODER_OPT_VALUE_RTSP_TRANSPORT_TCP forKey:VKDECODER_OPT_KEY_RTSP_TRANSPORT]];
  
  return viewz.view;
}

@end
