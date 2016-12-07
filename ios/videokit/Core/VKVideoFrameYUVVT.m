//
//  VKVideoFrameRGB.m
//  VideoKitSample
//
//  Created by Murat Sudan on 14/04/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import "VKVideoFrameYUVVT.h"

@implementation VKVideoFrameYUVVT

- (id) init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void) dealloc {
    CVPixelBufferRelease(_pixelBuffer);
    _pixelBuffer = nil;
    [super dealloc];
}


@end
