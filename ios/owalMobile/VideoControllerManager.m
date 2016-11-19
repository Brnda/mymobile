//
//  VideoController.m
//  owalMobile
//
//  Created by Mateo Barraza on 10/11/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "VideoControllerManager.h"
#import "VKPlayerController.h"

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
  
  VKPlayerController *controller = [[VKPlayerController alloc] initWithURLString:_uri];
  
  //Configure controller view for display.
  UIView *playerView = controller.view;
  playerView.translatesAutoresizingMaskIntoConstraints = NO;
  [controller setFullScreen:YES];
  controller.barTitle = _title;
  
  [parent addSubview:playerView];
   // align playerView from the horizontally.
  [parent addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[playerView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerView)]];
  // align playerView from the top.
  [parent addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[playerView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerView)]];
  
  //Set uri and automatically play stream
  controller.contentURLString = _uri;
  [controller play];
  
  return parent;
}

@end
