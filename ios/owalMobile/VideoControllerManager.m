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

- (UIView *)view
{  
  VideoControllerView *viewz = [[VideoControllerView alloc] initWithURLString:@"rtsp://admin:tpat2015@76.10.32.13/Streaming/Channels/1?transportmode=unicast&profile=Profile_1" decoderOptions:[NSDictionary dictionaryWithObject:VKDECODER_OPT_VALUE_RTSP_TRANSPORT_TCP forKey:VKDECODER_OPT_KEY_RTSP_TRANSPORT]];

//  NSLog(@"view is %@", NSStringFromCGRect(viewz.frame));
  return viewz.view;
}

@end