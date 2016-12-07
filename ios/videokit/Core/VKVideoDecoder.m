//
//  VKVideoDecoder.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "VKVideoDecoder.h"
#import "VKAudioDecoder.h"
#import "VKVideoFrameRGB.h"
#import "VKVideoFrameYUV.h"
#import "VKVideoFrameYUVVT.h"
#import "VKPacket.h"

//Notifications & UserInfo keys
NSString *kVKVideoFrameReadyForRenderNotification    = @"VKVideoFrameReadyForRender";
NSString *kVKVideoFrame                              = @"VKVideoFrame";

//Settings
static int decoder_reorder_pts      = -1; /* 0=off 1=on -1=auto */

//Defines
/* polls for possible required screen refresh at least this often, should be less than 1/fps */
#define REFRESH_RATE 0.01

static void fillFrameData(UInt8 *src, UInt8 *dst, int size, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    memset(dst, 0, size);
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
}

@interface VKVideoDecoder() {

    AVFormatContext* _avFmtCtx; /* avformat context reference */
    NSMutableArray *_pictQueue; /* picture (ready to display) queue */
    
    struct SwsContext *_imgConvertCtx; /* image format convertor, uses CPU */
    AVPicture _picture; /* */
    VKVideoStreamColorFormat _colorFormat;

    //mutex & condition
    pthread_mutex_t _mutexPictQueue; /* mutex for managing threads */
    pthread_cond_t _condPictQueue; /* condition for managing threads */

    //dispatch queues
    dispatch_queue_t _videoDecodeQueue;
    dispatch_queue_t _pictActionQueue;

    BOOL _decodeJobIsDone;
    BOOL _schedulePictureJobIsDone;

    BOOL _refreshInProgress;

    VKAudioDecoder *_audioDecoder; /* if audio works, then we will sync a-v due to audio */

    //frame related vars
    double _frameTimer;
    double _frameLastPts;
    int64_t _frameLastDroppedPos;
    double _frameLastDuration;
    double _frameLastDroppedPts;
    double _frameLastFilterDelay;
    int _frameDropsEarly;
    int _frameDropsLate;
    int64_t _currentPos;
    double _frameLastDelay;
    double _clock; /* pts of last decoded frame / predicted pts of next */
    int _frameDisplayCounter;
    int _frameLastDroppedSerial;

    //picture related vars
    int _pictQSize, _pictQRIndex, _pictQWIndex;

    //settings
    int _allowFrameDrop; /* drop frames when cpu is too slow */
    int _frameDisplayCycle;
    
    int _clockSerial;
    int _forceRefresh;
    BOOL _eof;
    double _remainingTime;

    dispatch_semaphore_t _semaSchedulePicThread;
    dispatch_semaphore_t _semaDecodeThread;
    
    int _avSyncLogIterator;
    int64_t last_time;
}

@end

@implementation VKVideoDecoder

@synthesize decodeJobIsDone = _decodeJobIsDone;
@synthesize schedulePictureJobIsDone = _schedulePictureJobIsDone;
@synthesize currentPos = _currentPos;

#pragma mark - Initialization

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (id)initWithFormatContext:(AVFormatContext*)avFmtCtx codecContext:(AVCodecContext*)cdcCtx stream:(AVStream *)strm
                   streamId:(NSInteger)sId manager:(id)manager audioDecoder:(VKAudioDecoder *)audioDecoder {
    self = [super initWithCodecContext:cdcCtx stream:strm streamId:sId manager:manager];
    if (self) {
        _audioDecoder = audioDecoder;
        _avFmtCtx = avFmtCtx;
        
        [self initMutex];
        [self createFrameBuffers];
        [self createDispatchQueues];
        [self initValues];
    }
    return self;
}

- (void)initMutex {
    pthread_mutex_init(&_mutexPictQueue, NULL);
    pthread_cond_init(&_condPictQueue, NULL);
}

- (void)createFrameBuffers {
    _pictQueue = [[NSMutableArray alloc] init];
    
    _colorFormat = [(VKDecodeManager *)_manager videoStreamColorFormat];
    if (_colorFormat == VKVideoStreamColorFormatRGB) {
        avpicture_alloc(&_picture, AV_PIX_FMT_RGBA, _codecContext->width, _codecContext->height);
    }
    
    int w = _codecContext->width;
    int h = _codecContext->height;
    int size = w*h;
    
    for (int i = 0; i < [(VKDecodeManager *)_manager videoPictureQueueSize]; i++) {
        
        VKVideoFrame *vidFrame = NULL;

        if (_colorFormat == VKVideoStreamColorFormatYUV) {
            VKVideoFrameYUV *vf = [[VKVideoFrameYUV alloc] init];
            vf.pLuma.size = size;
            vf.pLuma.data = (UInt8*)malloc(size);
            memset(vf.pLuma.data, 0, vf.pLuma.size);
            
            vf.pChromaB.size = size/2;
            vf.pChromaB.data = (UInt8*)malloc(size/2);
            memset(vf.pChromaB.data, 0, vf.pChromaB.size);
            
            vf.pChromaR.size = size/2;
            vf.pChromaR.data = (UInt8*)malloc(size/2);
            memset(vf.pChromaR.data, 0, vf.pChromaR.size);
            
            vidFrame = vf;
        } else if (_colorFormat == VKVideoStreamColorFormatRGB) {
            VKVideoFrameRGB *vf = [[VKVideoFrameRGB alloc] init];
            vf.pRGB.size = _picture.linesize[0]*h;
            vf.pRGB.data = (UInt8*)malloc(vf.pRGB.size);
            memset(vf.pRGB.data, 0, vf.pRGB.size);
            
            vidFrame = vf;
        } else if (_colorFormat == VKVideoStreamColorFormatYUVVT) {
            vidFrame = [[VKVideoFrameYUVVT alloc] init];
        }

        
        vidFrame.width = w;
        vidFrame.height = h;

        [_pictQueue addObject:vidFrame];
        [vidFrame release];
    }
}

- (void)recreateFrameBuffers {
    VKLog(kVKLogLevelDecoder, @"recreateFrameBuffers");
    pthread_mutex_lock(&_mutexPictQueue);
    [_pictQueue removeAllObjects];
    [_pictQueue release];
    _pictQueue = nil;
    avpicture_free(&_picture);
    
    [self createFrameBuffers];
    pthread_mutex_unlock(&_mutexPictQueue);
}

- (void)createDispatchQueues {
    _pictActionQueue = dispatch_queue_create("picture_schedule_and_refresh_queue", NULL);
    _videoDecodeQueue = dispatch_queue_create("frame_decode_queue", NULL);
}

- (void)initValues {
    _decodeJobIsDone = YES;
    _schedulePictureJobIsDone = YES;

    _refreshInProgress = NO;

    _frameTimer = (double)av_gettime() / 1000000.0;
    _currentPos = 0;
    _frameLastPts = 0;
    _frameLastDuration = 0;
    _frameLastDroppedPts = 0;
    _frameLastFilterDelay = 0;
    _frameLastDroppedPos = 0;
    _frameDropsEarly = 0;
    _frameDropsLate = 0;
    _frameLastDroppedSerial = 0;

    _pictQSize = _pictQRIndex = _pictQWIndex = 0;

    _clockSerial = -1;
    _remainingTime = 0.0;
    _eof = NO;
    
    _frameDisplayCycle = [(VKDecodeManager *)_manager frameDisplayCycle];
    _frameDisplayCounter = 0;
    
    _avSyncLogIterator = 0;
    last_time = 0;
    
    if ([(VKDecodeManager *)_manager disableDropVideoPackets]) {
        _allowFrameDrop = 0;
    } else {
        _allowFrameDrop = -1;
    }
    
    if (_avFmtCtx->iformat && _avFmtCtx->iformat->name && strlen(_avFmtCtx->iformat->name)) {
        NSString *fmtName = [NSString stringWithUTF8String:_avFmtCtx->iformat->name];
        if (([fmtName rangeOfString:@"mjpeg"].location != NSNotFound) && (!_audioDecoder)) {
            _allowFrameDrop = 0;
        }
    }
}

#pragma mark - Actions

#pragma mark Decode video frames to pictures

- (int)decodeVideo {

    _semaDecodeThread = dispatch_semaphore_create(0);
    __block BOOL isFirstFrame = YES;

    dispatch_async(_videoDecodeQueue, ^(void) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        AVPacket packet = { 0 };
        int gotPicture;
        __block VKPacket *vidPkt;
        _decodeJobIsDone = NO;
        
        AVFrame *frame = NULL;
        if (_ffmpegVersMajor > 1) {
            frame = av_frame_alloc();
        } else {
            //frame = avcodec_alloc_frame();
        }

        //int64_t ptsInt = AV_NOPTS_VALUE, pos = -1;
        __block double pts;
        int pktSerial = 0;
        
        av_init_packet(&packet);

        for (;;) {
            
            NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
            
            int retValue = 0;

            while (([(VKDecodeManager *)_manager streamIsPaused] ||
                    (_audioDecoder && [_audioDecoder isWaitingForPackets] &&
                     [(VKDecodeManager *)_manager remoteFileStreaming])) && !_abortRequest) {
                        NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
                        [NSThread sleepForTimeInterval:0.01];
                        [p release];
                    }
            if (_abortRequest) {
                [subPool release];
                break;
            }
            
            av_frame_unref(frame);

            /* try to get a packet, if successful decode it */
            BOOL isPktFlush = NO;

            pthread_mutex_lock(&_mutexPkt);
            int totalCount = (int)[_pktQueue count];
            if (!totalCount) {
                pthread_cond_wait(&_condPkt, &_mutexPkt);
            }

            vidPkt = (VKPacket *)[_pktQueue lastObject];
            if (!vidPkt) {
                _pktQueueSize = _pktQueueSize - vidPkt.size;
                [_pktQueue removeLastObject];
            }

            if (vidPkt.flush) {
                isPktFlush = YES;
                _pktQueueSize = _pktQueueSize - vidPkt.size;
                [_pktQueue removeLastObject];
                avcodec_flush_buffers(_codecContext);
            }
            pthread_mutex_unlock(&_mutexPkt);

            if (isPktFlush) {
                pthread_mutex_lock(&_mutexPictQueue);
                while (_pictQSize && !_abortRequest) {
                    pthread_cond_wait(&_condPictQueue, &_mutexPictQueue);
                }
                _currentPos = -1;
                _frameLastPts = AV_NOPTS_VALUE;
                _frameLastDuration = 0;
                _frameTimer = (double)av_gettime() / 1000000.0;
                _frameLastDroppedPts = AV_NOPTS_VALUE;
                pthread_mutex_unlock(&_mutexPictQueue);
                [subPool release];
                continue;
            }
            
            packet.data = (uint8_t *)[vidPkt.samples bytes];
            packet.size = vidPkt.size;
            packet.pts = vidPkt.pts;
            packet.dts = vidPkt.dts;
            packet.flags = vidPkt.flags;
            packet.duration = vidPkt.duration;
            pktSerial = vidPkt.serial;
            
            int decodeCode = avcodec_decode_video2(_codecContext, frame, &gotPicture, &packet);
            
            if (decodeCode < 0) {
                retValue = 0;
                usleep(10000);
            }

            if (gotPicture) {
                int ret = 1;
                double dpts = NAN;

                if (decoder_reorder_pts == -1) {
                    frame->pts = av_frame_get_best_effort_timestamp(frame);
                } else if (decoder_reorder_pts) {
                    frame->pts = frame->pkt_pts;
                } else {
                    frame->pts = frame->pkt_dts;
                }

                if (frame->pts != AV_NOPTS_VALUE)
                    dpts = av_q2d(_stream->time_base) * frame->pts;
                
                
                frame->sample_aspect_ratio = av_guess_sample_aspect_ratio(_avFmtCtx, _stream, frame);

                if ((_allowFrameDrop > 0) || (_allowFrameDrop &&
                                            [(VKDecodeManager *)_manager masterSyncType] != AV_SYNC_VIDEO_MASTER)) {

                    pthread_mutex_lock(&_mutexPictQueue);

                    if ((_frameLastPts != AV_NOPTS_VALUE) && (frame->pts != AV_NOPTS_VALUE)) {
                        double clockdiff = [_clockManager clockTime:_decoderClock] - [(VKDecodeManager *)_manager masterClock];
                        double ptsdiff = dpts - _frameLastPts;

                        if (!isnan(clockdiff) && fabs(clockdiff) < AV_NOSYNC_THRESHOLD &&
                           !isnan(ptsdiff > 0) && ptsdiff < AV_NOSYNC_THRESHOLD &&
                            clockdiff + ptsdiff - _frameLastFilterDelay < 0 &&
                            [_pktQueue count]) {
                            _frameLastDroppedPos = av_frame_get_pkt_pos(frame);
                            _frameLastDroppedPts = dpts;
                            _frameLastDroppedSerial = pktSerial;
                            _frameDropsEarly++;
                            av_frame_unref(frame);
                            ret = 0;
                        }
                    }
                    pthread_mutex_unlock(&_mutexPictQueue);
                }
                retValue = ret;
            }
            
            if (retValue < 0) {
                pthread_mutex_lock(&_mutexPkt);
                if (pktSerial == _queueSerial) {
                    _pktQueueSize = _pktQueueSize - packet.size;
                    [_pktQueue removeLastObject];
                }
                pthread_mutex_unlock(&_mutexPkt);
                [subPool release];
                goto the_end;
            }
            
            if (retValue == 0) {
                pthread_mutex_lock(&_mutexPkt);
                if (pktSerial == _queueSerial) {
                    _pktQueueSize = _pktQueueSize - packet.size;
                    [_pktQueue removeLastObject];
                }
                pthread_mutex_unlock(&_mutexPkt);
                [subPool release];
                continue;
            }

            pts = (frame->pts == AV_NOPTS_VALUE) ? NAN : frame->pts * av_q2d(_stream->time_base);

            retValue = [self queuePictureWithFrame:frame withPts:pts withPos:av_frame_get_pkt_pos(frame) withSerial:pktSerial];
            av_frame_unref(frame);

            if (retValue < 0) {
                pthread_mutex_lock(&_mutexPkt);
                if (pktSerial == _queueSerial) {
                    _pktQueueSize = _pktQueueSize - packet.size;
                    [_pktQueue removeLastObject];
                }
                pthread_mutex_unlock(&_mutexPkt);
                [subPool release];
                goto the_end;
            }

            pthread_mutex_lock(&_mutexPkt);
            NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
            if (pktSerial == _queueSerial) {
                _pktQueueSize = _pktQueueSize - packet.size;
                [_pktQueue removeLastObject];
            }
            [p release];
            pthread_mutex_unlock(&_mutexPkt);
            
            if (isFirstFrame && [(VKDecodeManager *)_manager showPicOnInitialBuffering]) {
                isFirstFrame = NO;
                [self performSelector:@selector(refreshPicture)];
            }
            [subPool release];
        }

    the_end:

        avcodec_flush_buffers(_stream->codec);
        av_free_packet(&packet);
        av_frame_free(&frame);

        VKLog(kVKLogLevelDecoder, @"decodeVideo is ENDED!");
        _decodeJobIsDone = YES;

        dispatch_semaphore_signal(_semaDecodeThread);

        [pool release];
    });

    return 0;
}

- (int)queuePictureWithFrame:(AVFrame *) pFrame withPts:(double) pts1
                     withPos:(int64_t) pos withSerial:(int) frameSerial {

    pthread_mutex_lock(&_mutexPictQueue);
    while (_pictQSize >= [(VKDecodeManager *)_manager videoPictureQueueSize] - 1 &&
           !_abortRequest) {
        pthread_cond_wait(&_condPictQueue, &_mutexPictQueue);
    }
    pthread_mutex_unlock(&_mutexPictQueue);

    if (_abortRequest)
        return -1;

    VKVideoStreamColorFormat colorFormat = [(VKDecodeManager *)_manager videoStreamColorFormat];
    VKVideoFrame *vidFrame = NULL;
    
    if (colorFormat == VKVideoStreamColorFormatYUV) {
        
        VKVideoFrameYUV *vidFrameYUV = [_pictQueue objectAtIndex:_pictQWIndex];
        
        if(vidFrameYUV.pLuma.size != _codecContext->width * _codecContext->height) {
            [self recreateFrameBuffers];
            _pictQSize = _pictQRIndex = _pictQWIndex = 0;
            return 0;
        }
        
        fillFrameData(pFrame->data[0], vidFrameYUV.pLuma.data, vidFrameYUV.pLuma.size, pFrame->linesize[0],
                      _codecContext->width, _codecContext->height);
        fillFrameData(pFrame->data[1], vidFrameYUV.pChromaB.data, vidFrameYUV.pChromaB.size, pFrame->linesize[1],
                      _codecContext->width/2, _codecContext->height/2);
        fillFrameData(pFrame->data[2], vidFrameYUV.pChromaR.data, vidFrameYUV.pChromaR.size, pFrame->linesize[2],
                      _codecContext->width/2, _codecContext->height/2);
        
        vidFrame = vidFrameYUV;
    } else if (colorFormat == VKVideoStreamColorFormatRGB) {

        
        VKVideoFrameRGB *vidFrameRGB = [_pictQueue objectAtIndex:_pictQWIndex];
        
        if(vidFrameRGB.pRGB.size != _picture.linesize[0] * _codecContext->height) {
            [self recreateFrameBuffers];
            _pictQSize = _pictQRIndex = _pictQWIndex = 0;
            return 0;
        }
        
        if (!_imgConvertCtx) {
            _imgConvertCtx = sws_getCachedContext(_imgConvertCtx, _codecContext->width, _codecContext->height,
                                               _codecContext->pix_fmt, _codecContext->width, _codecContext->height,
                                               AV_PIX_FMT_RGBA, SWS_FAST_BILINEAR, NULL, NULL, NULL);
        }
        sws_scale(_imgConvertCtx, (const uint8_t **)pFrame->data, pFrame->linesize,
                      0, _codecContext->height, _picture.data, _picture.linesize);
        memcpy(vidFrameRGB.pRGB.data, _picture.data[0], _picture.linesize[0] * _codecContext->height);
        
        vidFrame = vidFrameRGB;
    } else if (_colorFormat == VKVideoStreamColorFormatYUVVT){
        VKVideoFrameYUVVT *vidFrameYUVVT = [_pictQueue objectAtIndex:_pictQWIndex];
        CVPixelBufferRef cv_buffer = ( CVPixelBufferRef )pFrame->data[3];
        vidFrameYUVVT.pixelBuffer = CVPixelBufferRetain(cv_buffer);
        vidFrame = vidFrameYUVVT;
    }

    vidFrame.width = _codecContext->width;
    vidFrame.height = _codecContext->height;
    vidFrame.pts = pts1;
    vidFrame.pos = pos;
    vidFrame.serial = frameSerial;

    AVRational ratio = av_guess_sample_aspect_ratio(_avFmtCtx , _stream, pFrame);
    if (ratio.num == 0)
        vidFrame.aspectRatio = 0;
    else
        vidFrame.aspectRatio = av_q2d(ratio);

    if (vidFrame.aspectRatio <= 0.0)
        vidFrame.aspectRatio = 1.0;

    _pictQWIndex++;
    if (_pictQWIndex == [(VKDecodeManager *)_manager videoPictureQueueSize]){
        _pictQWIndex = 0;
    }
    pthread_mutex_lock(&_mutexPictQueue);
    _pictQSize++;
    pthread_mutex_unlock(&_mutexPictQueue);

    return 0;
}

#pragma mark Setting picture ready

- (void) schedulePicture {

    _semaSchedulePicThread = dispatch_semaphore_create(0);
    dispatch_async(_pictActionQueue, ^(void) {
        _schedulePictureJobIsDone = NO;
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        while (!_abortRequest) {
            if (_remainingTime > 0.0) {
                unsigned int val = (unsigned int)(_remainingTime * 1000000.0);
                av_usleep(val);
            }
            _remainingTime = REFRESH_RATE;
            if (!_refreshInProgress && (_forceRefresh ||
                                        ![(VKDecodeManager *)_manager remoteFileStreaming] ||
                                        !([(VKDecodeManager *)_manager streamIsPaused] ||
                                          (_audioDecoder && [_audioDecoder isWaitingForPackets])))) {
                _refreshInProgress = YES;
                [self performSelector:@selector(refreshPicture)];
            }
        }

        _schedulePictureJobIsDone = YES;
        VKLog(kVKLogLevelDecoder, @"schedulePicture is ENDED");

        dispatch_semaphore_signal(_semaSchedulePicThread);
        [pool release];
    });

}

- (void) refreshPicture {

    double time;

    if (![(VKDecodeManager *)_manager streamIsPaused] &&
        [(VKDecodeManager *)_manager masterSyncType] == AV_SYNC_EXTERNAL_CLOCK &&
        [(VKDecodeManager *)_manager isRealTime]) {
        [(VKDecodeManager *)_manager checkExternalClockSpeed];
    }

    if (_stream) {

        int redisplay = 0;
        if (_forceRefresh)
            redisplay = [self pictqPrevPicture];

    retry:

        if (_abortRequest) {
            return;
        }

        if (_pictQSize == 0) {
            pthread_mutex_lock(&_mutexPictQueue);
            if (_frameLastDroppedPts != AV_NOPTS_VALUE && _frameLastDroppedPts > _frameLastPts) {
                [self updateVideoWithPts:_frameLastDroppedPts withPos:_frameLastDroppedPos withSerial:_frameLastDroppedSerial];
                _frameLastDroppedPts = AV_NOPTS_VALUE;
            }
            pthread_mutex_unlock(&_mutexPictQueue);

            // nothing to do, no picture to display in the queue
        } else {
            double lastDuration, duration, delay;
            duration = 0.0;
            VKVideoFrame *vidFrame;

            vidFrame = [_pictQueue objectAtIndex:_pictQRIndex];

            if (vidFrame.serial != _queueSerial) {
                [self pictqNextPicture:vidFrame];
                redisplay = 0;
                goto retry;
            }

            if (!_abortRequest && [(VKDecodeManager *)_manager streamIsPaused]){
                goto display;
            }

            /* compute nominal last_duration */
            lastDuration = vidFrame.pts - _frameLastPts;
            if (!isnan(lastDuration) && lastDuration > 0 && lastDuration < [(VKDecodeManager *)_manager maxFrameDuration]) {
                /* if duration of the last frame was sane, update last_duration in video state */
                _frameLastDuration = lastDuration;
            }
            
            if (redisplay) {
                delay = 0.0;
            } else {
                delay = [self computeTargetDelayWithVal:_frameLastDuration];
            }
            
            time = av_gettime()/1000000.0;

            if (time < (_frameTimer + delay) && !redisplay) {
                //VKLog(kVKLogLevelDecoder, @"time:%f  / _frametimer(%f) + delay(%f):%f", time, _frameTimer, delay, (_frameTimer + delay));
                
                _remainingTime = FFMIN(_frameTimer + delay - time, _remainingTime);
                _refreshInProgress = NO;
                return;
            }
            
            _frameTimer += delay;
            
            if (delay > 0 && time - _frameTimer > AV_SYNC_THRESHOLD_MAX)
                _frameTimer = time;
        
            pthread_mutex_lock(&_mutexPictQueue);
            if (!redisplay && !isnan(vidFrame.pts))
                [self updateVideoWithPts:vidFrame.pts withPos:vidFrame.pos withSerial:vidFrame.serial];
            pthread_mutex_unlock(&_mutexPictQueue);

            if (_pictQSize > 1) {
                VKVideoFrame *nextVidFrame = [_pictQueue objectAtIndex:((_pictQRIndex + 1) % [(VKDecodeManager *)_manager videoPictureQueueSize])];
                duration = nextVidFrame.pts - vidFrame.pts; // More accurate this way, 1/time_base is often not reflecting FPS

                if (_audioDecoder) {
                    if(![(VKDecodeManager *)_manager step] && (redisplay || _allowFrameDrop > 0 || (_allowFrameDrop && [(VKDecodeManager *)_manager masterSyncType] != AV_SYNC_VIDEO_MASTER)) && time > _frameTimer + duration){
                        if (!redisplay)
                            _frameDropsLate++;
                        [self pictqNextPicture:vidFrame];
                        redisplay = 0;
                        goto retry;
                    }
                }
            }

        display:
            /* display picture */
            if (!_abortRequest){
                if (![(VKDecodeManager *)_manager appIsInBackgroundNow]) {
                    if (_frameDisplayCounter % _frameDisplayCycle == 0) {
                        _frameDisplayCounter = 0;
                        [self performSelectorOnMainThread:@selector(displayPicture) withObject:nil waitUntilDone:YES];
                    }
                    _frameDisplayCounter++;
                } else {
                    [NSThread sleepForTimeInterval:REFRESH_RATE];
                }
                [self pictqNextPicture:vidFrame];
            }
            if ([(VKDecodeManager *)_manager step] && ![(VKDecodeManager *)_manager streamIsPaused])
                [(VKDecodeManager *)_manager streamTogglePause];
        }
    }

    _forceRefresh = 0;
    
    if (!_eof) {
        int modSync = 1/[(VKDecodeManager *)_manager avSyncLogFrequency];
        
        if((log_level & kVKLogLevelAVSync) && (_avSyncLogIterator % modSync == 0)){
            _avSyncLogIterator = 0;

            int64_t cur_time;
            long aqsize, vqsize, sqsize;
            double av_diff;
            
            cur_time = av_gettime();
            
            if (!last_time || (cur_time - last_time) >= 30000) {
                aqsize = 0;
                vqsize = 0;
                sqsize = 0;
                if (_audioDecoder) {
                    aqsize = [_audioDecoder pktQueueSize];
                }
                vqsize = _pktQueueSize;

                av_diff = 0;
                if (_audioDecoder) {
                    double aClk = [_clockManager clockTime:_audioDecoder.decoderClock];
                    double vClk = [_clockManager clockTime:_decoderClock];
                    av_diff =  aClk - vClk;
                    av_log(NULL, AV_LOG_INFO, ">>>> aClk:%7.4f - vClk:%7.4f\n", aClk, vClk);
                }
                else {
                    double mClk = [(VKDecodeManager *)_manager masterClock];
                    double vClk = [_clockManager clockTime:_decoderClock];
                    av_diff = mClk - vClk;
                    av_log(NULL, AV_LOG_INFO, ">>>> mClk:%7.4f - vClk:%7.4f\n", mClk, vClk);
                }
                
                
                av_log(NULL, AV_LOG_INFO,
                       "%7.2f %s:%7.3f fd=%4d aq=%5ldKB vq=%5ldKB f=%"PRId64"/%"PRId64"   \r",
                       [(VKDecodeManager *)_manager masterClock],
                       (_audioDecoder) ? "A-V" : "M-V",
                       av_diff,
                       _frameDropsEarly + _frameDropsLate,
                       aqsize / 1024,
                       vqsize / 1024,
                       _stream->codec->pts_correction_num_faulty_dts,
                       _stream->codec->pts_correction_num_faulty_pts);
                
                fflush(stdout);
                last_time = cur_time;
            }

        }
        _avSyncLogIterator++;
    }
    _refreshInProgress = NO;
}

- (void) displayPicture {
    VKVideoFrame *vidFrame;
    vidFrame = [_pictQueue objectAtIndex:_pictQRIndex];
    
    if (!vidFrame)
        return;
    
    if ((_colorFormat == VKVideoStreamColorFormatYUV) &&
        ([(VKVideoFrameYUV *)vidFrame pLuma].size != vidFrame.width * vidFrame.height)) {
        return;
    }
    
    if (!(_abortRequest || [(VKDecodeManager *)_manager appIsInBackgroundNow])) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kVKVideoFrameReadyForRenderNotification object:_manager userInfo:@{kVKVideoFrame : vidFrame}];
    }
}

#pragma mark AV syncing

- (double) computeTargetDelayWithVal:(double) delay
{
    double syncThreshold, diff;

    /* update delay to follow master synchronisation source */
    if ([(VKDecodeManager *)_manager masterSyncType] != AV_SYNC_VIDEO_MASTER) {
        /* if video is slave, we try to correct big delays by
         duplicating or deleting a frame */
        diff = [_clockManager clockTime:_decoderClock] - [(VKDecodeManager *)_manager masterClock];

        /* skip or repeat frame. We take into account the
         delay to compute the threshold. I still don't know
         if it is the best guess */
        syncThreshold = FFMAX(AV_SYNC_THRESHOLD_MIN, FFMIN(AV_SYNC_THRESHOLD_MAX, delay));
        if (!isnan(diff) && fabs(diff) < [(VKDecodeManager *)_manager maxFrameDuration]) {
            if (diff <= -syncThreshold)
                delay = FFMAX(0, delay + diff);
            else if (diff >= syncThreshold && delay > AV_SYNC_FRAMEDUP_THRESHOLD)
                delay = delay + diff;
            else if (diff >= syncThreshold)
                delay = 2 * delay;
        }
    }
    return delay;
}

-(int)pictqPrevPicture {

    VKVideoFrame *prevVidFrame;
    int ret = 0;
    int picQueueSizeDefined = [(VKDecodeManager *)_manager videoPictureQueueSize];
    int prevIndex = ((_pictQRIndex + picQueueSizeDefined -1) % picQueueSizeDefined);
    prevVidFrame = [_pictQueue objectAtIndex:prevIndex];

    if (prevVidFrame && prevVidFrame.serial == _queueSerial) {
        pthread_mutex_lock(&_mutexPictQueue);

        if (_pictQSize < (picQueueSizeDefined)) {
            if ((_pictQRIndex - 1) == -1)
                _pictQRIndex = picQueueSizeDefined - 1;
            _pictQSize++;
            ret = 1;
        }
        pthread_cond_signal(&_condPictQueue);
        pthread_mutex_unlock(&_mutexPictQueue);
    }
    return ret;
}

- (void)pictqNextPicture:(VKVideoFrame *)vidFrame {
    
    /* update queue size and signal for next picture */
    
    if (_colorFormat == VKVideoStreamColorFormatYUVVT) {
        VKVideoFrameYUVVT *vidFrameYUVVT = (VKVideoFrameYUVVT *)vidFrame;
        if ([vidFrameYUVVT pixelBuffer]) {
            CVPixelBufferRelease(vidFrameYUVVT.pixelBuffer);
            vidFrameYUVVT.pixelBuffer = NULL;
        }
    }
    
    _pictQRIndex++;
    if (_pictQRIndex == [(VKDecodeManager *)_manager videoPictureQueueSize]) {
        _pictQRIndex = 0;
    }

    pthread_mutex_lock(&_mutexPictQueue);
    _pictQSize--;
    pthread_cond_signal(&_condPictQueue);
    pthread_mutex_unlock(&_mutexPictQueue);
}

-(void) updateVideoWithPts:(double) pts withPos:(int64_t) pos withSerial:(int) pktSerial {
    [_clockManager setClockTime:_decoderClock pts:pts serial:pktSerial];
    [_clockManager syncClockToSlave:[(VKDecodeManager *)_manager externalClock] slave:_decoderClock];
    _currentPos = pos;
    _frameLastPts = pts;
    
}

#pragma mark - On State change actions

- (void)onStreamPaused {
    _frameTimer += av_gettime() / 1000000.0 + _decoderClock.ptsDrift - _decoderClock.pts;
    
    if ([(VKDecodeManager *)_manager readPauseCode] != AVERROR(ENOSYS)) {
        _decoderClock.paused = 0;
    }
    [_clockManager setClockTime:_decoderClock pts:[_clockManager clockTime:_decoderClock] serial:_decoderClock.serial];
}

- (void)onAudioStreamCycled:(VKAudioDecoder *)decoder {
    if (decoder) {
        _audioDecoder = decoder;
    }
}

- (void)onAudioDecoderDestroyed {
    _audioDecoder = NULL;
}

- (void)setEOF:(BOOL)value {
    _eof = value;
}

#pragma mark - Shutdown

- (void)shutdown {

    [self unlockQueues];

    if (_semaSchedulePicThread) {
        dispatch_semaphore_wait(_semaSchedulePicThread, DISPATCH_TIME_FOREVER);
        dispatch_release(_semaSchedulePicThread);
        _semaSchedulePicThread = NULL;
    }

    if (_semaDecodeThread) {
        dispatch_semaphore_wait(_semaDecodeThread, DISPATCH_TIME_FOREVER);
        dispatch_release(_semaDecodeThread);
        _semaDecodeThread = NULL;
    }

    if (_streamId >= 0) {
		_stream->discard = AVDISCARD_ALL;
	}
    
    if (_codecContext) {
        avcodec_close(_codecContext);
    }
    [self clearPktQueue];
}

- (void)unlockQueues {
    pthread_mutex_lock(&_mutexPictQueue);
    _pictQSize--;
    pthread_cond_signal(&_condPictQueue);
    pthread_mutex_unlock(&_mutexPictQueue);
    
    [super unlockQueues];
}

- (void)dealloc {
    VKLog(kVKLogLevelDecoder, @"Video Decoder is deallocated...");
    
    if (_imgConvertCtx) {
        sws_freeContext(_imgConvertCtx);
    }
    avpicture_free(&_picture);
    
    pthread_cond_destroy(&_condPictQueue);
    pthread_mutex_destroy(&_mutexPictQueue);
    
    [_pictQueue removeAllObjects];
    [_pictQueue release];
    
    dispatch_release(_videoDecodeQueue);
    dispatch_release(_pictActionQueue);
    
    [super dealloc];
}

#pragma clang diagnostic pop

@end
