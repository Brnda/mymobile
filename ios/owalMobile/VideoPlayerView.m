//
//  VideoPlayerView.h
//  owalMobile
//
//  Created by Mateo Barraza on 12/13/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "VKPlayerController.h"
#import "VKAVDecodeManager.h"
#import "VKGLES2ViewRGB.h"
#import "VKGLES2ViewYUVVT.h"
#import "VKGLES2ViewYUV.h"
#import "VideoPlayerView.h"

@interface VideoPlayerView ()<VKDecoderDelegate>{
  
}
@end

@implementation VideoPlayerView
- (void) play {
  NSLog(@"Playing video %@", [self uri]);
  
  dispatch_async(dispatch_queue_create("play_stop_lock", NULL), ^(void) {
    VKAVDecodeManager* _decodeManager = [[VKAVDecodeManager alloc] initWithUsername:@"" secret:@""];
    if (_decodeManager) {
      _decodeManager.delegate = self;
      
      //extra parameters
      _decodeManager.avPacketCountLogFrequency = 0.01;
      [_decodeManager setLogLevel:kVKLogLevelStateChanges];
      [_decodeManager setInitialAVSync:YES];
      
      VKError error = [_decodeManager connectWithStreamURLString:[self uri] options:nil];
      
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
          
          if ([_renderView initGLWithDecodeManager:_decodeManager bounds:self.bounds] == kVKErrorNone) {
            [self addSubview:_renderView];
            
            //readPackets and start decoding
            [_decodeManager startToReadAndDecode];
          }
        }
      });
    }
  });
}


#pragma mark - Callbacks VKDecoderDelegate

- (void)decoderStateChanged:(VKDecoderState)state errorCode:(VKError)errCode {
  NSLog(@"Received state");
}

@end
