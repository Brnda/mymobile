//
//  VKVideoFrameRGB.m
//  VideoKitSample
//
//  Created by Murat Sudan on 14/04/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import "VKVideoFrameRGB.h"

@implementation VKVideoFrameRGB

- (id) init {
    self = [super init];
    if (self) {
        _pRGB = [[VKColorPlane alloc] init];
    }
    return self;
}

- (void) dealloc {
    [_pRGB release];
    [super dealloc];
}


@end
