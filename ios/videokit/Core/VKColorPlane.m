//
//  VKColorPlane.m
//  VideoKitSample
//
//  Created by Murat Sudan on 14/04/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import "VKColorPlane.h"

@implementation VKColorPlane

- (id)init {
    self = [super init];
    return self;
}

- (void)dealloc {
    if (_data && _size) {
        free(_data);
        _data = NULL;
    }
    [super dealloc];
}

@end
