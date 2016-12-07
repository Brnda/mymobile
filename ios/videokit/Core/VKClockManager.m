//
//  VKClockManager.m
//  VideoKitSample
//
//  Created by Murat Sudan on 18/09/15.
//  Copyright (c) 2015 iosvideokit. All rights reserved.
//

#import "VKClockManager.h"

@implementation VKClockManager

#pragma mark - Manager initialization

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - Clock management

- (void)initClock:(VKClock *)clock serial:(int *)serial {
    clock.speed = 1.0;
    clock.paused = 0;
    clock.queueSerial = serial;
    [self setClockTime:clock pts:NAN serial:-1];
}

- (void)setPts:(double)pts serial:(int)serial clock:(VKClock *)clock {
    double time = av_gettime() / 1000000.0;
    [self setTime:time pts:pts serial:serial clock:clock];
}

- (void)setTime:(double)time pts:(double)pts serial:(int)serial clock:(VKClock *)clock {
    clock.pts = pts;
    clock.last_updated = time;
    clock.ptsDrift = clock.pts - time;
    clock.serial = serial;
}

- (void)setSpeed:(double)speed clock:(VKClock *)clock {
    [self setClockTime:clock pts:[self clockTime:clock] serial:clock.serial];
    clock.speed = speed;
}

- (double)clockTime:(VKClock *)clock {
    if (*(clock.queueSerial) != clock.serial)
        return NAN;
    if (clock.paused) {
        return clock.pts;
    } else {
        double time = av_gettime() / 1000000.0;
        return clock.ptsDrift + time - (time - clock.last_updated) * (1.0 - clock.speed);
    }
}

- (void)setClockTime:(VKClock *)clock pts:(double)pts serial:(int)serial {
    double time = av_gettime() / 1000000.0;
    [self setTime:time pts:pts serial:serial clock:clock];
}

#pragma mark - AV Sync

- (void)syncClockToSlave:(VKClock *)clock slave:(VKClock *)slaveClock {
    double time = [self clockTime:clock];
    double timeSlave = [self clockTime:slaveClock];
    
    if (!isnan(timeSlave) && (isnan(time) || fabs(time - timeSlave) > AV_NOSYNC_THRESHOLD)) {
        [self setClockTime:clock pts:timeSlave serial:slaveClock.serial];
    }
}

@end
