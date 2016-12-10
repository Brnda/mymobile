//
//  VideoController.m
//  owalMobile
//
//  Created by Mateo Barraza on 10/11/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "VideoControllerManager.h"
#import "VKPlayerController.h"
#import "VKAVDecodeManager.h"
#import "VKGLES2ViewRGB.h"
#import "VKGLES2ViewYUVVT.h"
#import "VKGLES2ViewYUV.h"

@interface VideoControllerManager ()<VKDecoderDelegate>{
  
}
@end

@implementation VideoControllerManager

static NSString* _uri = @"";
static NSString* _title = @"";

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(setURI:(NSString* )uri title:(NSString* )title) {
  _uri = uri;
  _title = title;
}

- (UIView *)view
{
  UIView *parent = [[UIView alloc] init];
  UIView *playerView = [[UIView alloc]initWithFrame:CGRectMake(0, 50, 200, 130)];
  [playerView setBackgroundColor:[UIColor yellowColor]];
  
  //  NSDictionary *_decodeOptions = nil;
  dispatch_async(dispatch_queue_create("play_stop_lock", NULL), ^(void) {
    VKAVDecodeManager* _decodeManager = [[VKAVDecodeManager alloc] initWithUsername:@"" secret:@""];
    if (_decodeManager) {
      _decodeManager.delegate = self;
      
      //extra parameters
      _decodeManager.avPacketCountLogFrequency = 0.01;
      [_decodeManager setLogLevel:kVKLogLevelStateChanges];
      [_decodeManager setInitialAVSync:YES];
      
      VKError error = [_decodeManager connectWithStreamURLString:@"rtsp://prod-vpn.p.owal.io:28718/proxyStream" options:nil];
      
      dispatch_sync(dispatch_get_main_queue(), ^{
        VKGLES2View *_renderView;
        if (error == kVKErrorNone) {
          //create glview to render video pictures
          if ([_decodeManager videoStreamColorFormat] == VKVideoStreamColorFormatRGB) {
            _renderView = [[VKGLES2ViewRGB alloc] init];
          } else if([_decodeManager videoStreamColorFormat] == VKVideoStreamColorFormatYUVVT) {
            _renderView = [[VKGLES2ViewYUVVT alloc] init];
          } else {
            _renderView = [[VKGLES2ViewYUV alloc] init];
          }
          
          if ([_renderView initGLWithDecodeManager:_decodeManager bounds:playerView.bounds] == kVKErrorNone) {
            [playerView addSubview:_renderView];
            
            //readPackets and start decoding
            [_decodeManager startToReadAndDecode];
            
          }
        }
      });
    }
  });
  [parent addSubview:playerView];
  return parent;
}

#pragma mark - Callbacks VKDecoderDelegate

- (void)decoderStateChanged:(VKDecoderState)state errorCode:(VKError)errCode {
  NSLog(@"Received state");
}

@end
