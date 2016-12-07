//
//  MyPacket.m
//  VideoKitSample
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "VKPacket.h"

@interface VKPacket () {
    int _size;
    double _pts;
    double _dts;
    int64_t _pos;
    int _serial;
    BOOL _flush;
    NSData *_samples;
    
    int _streamIndex;
    int64_t _duration;
    double _modifiedPts;
    double _modifiedDts;
    int64_t _modifiedDuration;
    int _flags;
}

@end

@implementation VKPacket

@synthesize size = _size;
@synthesize pts = _pts;
@synthesize dts = _dts;
@synthesize pos = _pos;
@synthesize serial = _serial;
@synthesize flush = _flush;
@synthesize samples = _samples;
@synthesize streamIndex = _streamIndex;
@synthesize duration = _duration;
@synthesize flags = _flags;
@synthesize modifiedDts = _modifiedDts;
@synthesize modifiedPts = _modifiedPts;
@synthesize modifiedDuration = _modifiedDuration;

- (id) initWithPkt:(AVPacket *) pkt serial:(int) serial isFlush:(BOOL) flush {
    
    self = [super init];
    if (self) {
        _size = pkt->size;
        _pts = pkt->pts;
        _dts = pkt->dts;
        _pos = pkt->pos;
        _serial = serial;
        _streamIndex = pkt->stream_index;
        _duration = pkt->duration;
        _flags = pkt->flags;
        _flush = flush;

        _modifiedDts = _pts;
        _modifiedPts = _dts;
        _modifiedDuration = _duration;
        
        if (_size)
            _samples = [[NSData alloc] initWithBytes:pkt->data length:_size + FF_INPUT_BUFFER_PADDING_SIZE];
        else
            _samples = [[NSData alloc] initWithBytes:pkt->data length:_size];
    }
    return self;
}

- (void) dealloc {
    
    [_samples release];
    [super dealloc];
}

@end
