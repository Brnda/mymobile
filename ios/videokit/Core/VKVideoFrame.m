//
//  VideoFrame.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "VKVideoFrame.h"

@interface VKVideoFrame ()

@end

@implementation VKVideoFrame

@synthesize width, height, pts;
@synthesize pos, serial, aspectRatio;

- (id) init {
    self = [super init];
    if (self) {
        self.width = 0;
        self.height = 0;
        self.pts = 0.0;
        self.pos = 0;
        self.serial = 0;
        self.aspectRatio = 1.0;
    }
    return self;
}

- (void) dealloc {
    
    [super dealloc];
}

@end
