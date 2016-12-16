//
//  VideoController.m
//  owalMobile
//
//  Created by Mateo Barraza on 10/11/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "VideoControllerManager.h"
#import "VideoPlayerView.h"
#import "RCTUIManager.h"

@implementation VideoControllerManager


RCT_EXPORT_MODULE()

RCT_EXPORT_VIEW_PROPERTY(uri, NSString)

/*
 * Command method from JS to play() video. If URI is null then igore play()
 * This assumes that uri prop has been set in the JSX, it can initially be null until it has been 
 * fetched from the backend. Once fetched then we can set it via Redux as a connected props which 
 * will update the render()props.
 */

RCT_EXPORT_METHOD(play:(nonnull NSNumber *)reactTag) {
  [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, VideoPlayerView*> *viewRegistry) {
    VideoPlayerView *view = viewRegistry[reactTag];
    if (!view || ![view isKindOfClass:[VideoPlayerView class]]) {
      RCTLogError(@"Cannot find RCTMessagesView with tag #%@", reactTag);
      return;
    }
    [view play];
  }];
}

- (UIView *)view
{
  VideoPlayerView *parent = [VideoPlayerView new];
  return parent;
}


@end
