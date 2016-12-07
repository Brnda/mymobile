//
//  VKQueue.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "VKQueue.h"

@implementation VKQueue

@synthesize pktQueueSize = _pktQueueSize;
@synthesize pktQueue = _pktQueue;
@synthesize abortRequest = _abortRequest;

#pragma mark - Initialization

- (id)init {
    self = [super init];
    
    if (self) {
        
        _abortRequest = 0;
        _queueSerial = 0;
        
        [self initPktMutex];
        [self createPktQueue];
        [self createFlushPkt];
        [self startPktQueue];
    }
    return self;
}

- (void)initPktMutex {
    pthread_mutex_init(&_mutexPkt, NULL);
    pthread_cond_init(&_condPkt, NULL);
}

- (void)createPktQueue {
    _pktQueue = [[NSMutableArray alloc] init];
    _pktQueueSize = 0;
}

- (void)createFlushPkt {
    av_init_packet(&_flushPkt);
    _flushPkt.data = (uint8_t *)(intptr_t)"FLUSH";
    _flushPkt.size = (int)strlen((const char *)_flushPkt.data);
}

#pragma mark - Mutex & condition for managing packets processing priority

- (pthread_mutex_t*)mutexPkt {
    return &_mutexPkt;
}

- (pthread_cond_t*)condPkt {
    return &_condPkt;
}

#pragma mark - Actions

- (void)startPktQueue {
    [self addFlushPkt];
}

- (void)addFlushPkt {
    [self addPacket:&_flushPkt];
}

- (void)addEmptyPkt {
    AVPacket packet;
    av_init_packet(&packet);
    packet.data = NULL;
    packet.size = 0;
    packet.stream_index = (int)_queueSerial;
    pthread_mutex_lock(&_mutexPkt);
    [self addPacket:&packet];
    pthread_cond_signal(&_condPkt);
    pthread_mutex_unlock(&_mutexPkt);
}

- (void)addPacket:(AVPacket*)packet {
    
    if (_abortRequest) {
        return;
    }
    
    BOOL isFlushPkt = NO;
    if (packet == &_flushPkt){
        _queueSerial++;
        isFlushPkt = YES;
    }
    
    _pktQueueSize = _pktQueueSize + packet->size;
    VKPacket *streamPkt = [[VKPacket alloc] initWithPkt:packet serial:_queueSerial isFlush:isFlushPkt];
    [_pktQueue insertObject:streamPkt atIndex:0];
    [streamPkt release];
}

#pragma mark - Shutdown

- (void)clearPktQueue {
    if ([_pktQueue count]) {
        [_pktQueue removeAllObjects];
        _pktQueueSize = 0;
    }
}

- (void)unlockQueues {
    pthread_mutex_lock(&_mutexPkt);
    pthread_cond_signal(&_condPkt);
    pthread_mutex_unlock(&_mutexPkt);
}

- (void)dealloc {
    
    pthread_cond_destroy(&_condPkt);
    pthread_mutex_destroy(&_mutexPkt);
    [_pktQueue release];
    [super dealloc];
}


@end
