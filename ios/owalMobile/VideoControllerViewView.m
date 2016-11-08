//
//  VideoControllerViewView.m
//  owalMobile
//
//  Created by Yakov Okshtein on 11/7/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "VideoControllerViewView.h"

@implementation VideoControllerViewView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setUri:(NSString *)uri {
  NSLog(@"Setting URI to %@", uri);
  if ([self controller] != nil) {
    [self.controller playUri:uri];
  }
}

@end
