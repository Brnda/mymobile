//
//  VKClock.m
//  VideoKitSample
//
//  Created by Murat Sudan on 13/09/15.
//  Copyright (c) 2015 iosvideokit. All rights reserved.
//

#import "VKClock.h"

@implementation VKClock

- (id)initWithType:(VKClockType)type {
    self = [super init];
    if (self) {
        _serial = 0;
        _type = type;
    }
    return self;
}

- (int*)serialPtr {
    return &_serial;
}

- (void)dealloc {
    
    [super dealloc];
}

@end
