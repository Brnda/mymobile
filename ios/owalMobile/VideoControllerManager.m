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

RCT_EXPORT_MODULE()
RCT_EXPORT_VIEW_PROPERTY(uri, NSString)

- (UIView *)view
{  
  VideoControllerView *viewz = [[VideoControllerView alloc] initWithDecoderOptions:[NSDictionary dictionaryWithObject:VKDECODER_OPT_VALUE_RTSP_TRANSPORT_TCP forKey:VKDECODER_OPT_KEY_RTSP_TRANSPORT]];
  viewz.username = @"sol@owal.io";
  viewz.secret = @"a285d4025ca53fd8bd75ab3402d0f88e";
//  NSLog(@"view is %@", NSStringFromCGRect(viewz.frame));
  return viewz.view;
}

@end
