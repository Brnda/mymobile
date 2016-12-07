//
//  VKDecoder.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "VKDecoder.h"
#import "VKPacket.h"
#import "VKClock.h"

@implementation VKDecoder

@synthesize streamId = _streamId;
@synthesize manager = _manager;
@synthesize decoderClock = _decoderClock;

#pragma mark - Initialization

- (id)initWithCodecContext:(AVCodecContext*)cdcCtx stream:(AVStream *)strm streamId:(NSInteger)sId manager:(id)manager {
    self = [super init];
    if (self) {
        _manager = manager;
        _codecContext = cdcCtx;
        _stream = strm;
        _streamId = sId;
        _clockManager = [(VKDecodeManager *)_manager clockManager];
        
        if ([[(VKDecodeManager *)manager ffmpegVersion] length]) {
            _ffmpegVersMajor = [[[(VKDecodeManager *)manager ffmpegVersion] substringToIndex:1] intValue];
        } else {
            _ffmpegVersMajor = 2;
        }
        
        [self initDecoderClock];
    }
    return self;
}

- (void)initDecoderClock {
    VKClockType clockType = 0;
    
    if (_codecContext->codec_type == AVMEDIA_TYPE_AUDIO ) {
        clockType = kVKClockTypeAudio;
    } else if (_codecContext->codec_type == AVMEDIA_TYPE_VIDEO) {
        clockType = kVKClockTypeVideo;
    }
    _decoderClock = [[VKClock alloc] initWithType:clockType];
    [_clockManager initClock:_decoderClock serial:&_queueSerial];
}

- (void)dealloc {
    [_decoderClock release];
    [super dealloc];
}


@end
