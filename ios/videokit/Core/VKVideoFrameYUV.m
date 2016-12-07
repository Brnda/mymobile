//
//  VKVideoFrameYUV.m
//  VideoKitSample
//
//  Created by Murat Sudan on 14/04/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import "VKVideoFrameYUV.h"

@implementation VKVideoFrameYUV

- (id) init {
    self = [super init];
    if (self) {
        _pLuma = [[VKColorPlane alloc] init];
        _pChromaB = [[VKColorPlane alloc] init];
        _pChromaR = [[VKColorPlane alloc] init];
    }
    return self;
}

- (void) dealloc {
    
    [_pLuma release];
    [_pChromaB release];
    [_pChromaR release];
    
    [super dealloc];
}

@end
