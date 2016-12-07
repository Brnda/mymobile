//
//  VKRecorder.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "VKRecorder.h"
#import "VKDecodeManager.h"

#include <libavutil/timestamp.h>
#include "libavutil/mathematics.h"

const int copy_tb	= -1;

#define VK_RECORDING_DEFAULT_FOLDER_PATH        [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"]
#define VK_RECORDING_DEFAULT_CONTAINER          @"mkv"

typedef NS_ENUM(NSUInteger, VKRecorderState) {
    kVKRecorderStateNone,
    kVKRecorderStateInitializing,
    kVKRecorderStateRecording,
    kVKRecorderStateRecordingDone,
    kVKRecorderStateRecordingFailed
};

@interface VKRecorder () {
    
    //Output format & context
    AVOutputFormat *_outputFmt;
    AVFormatContext *_inputFmtCtx, *_outputFmtCtx;
    VKRecorderState _state;
    
    AVPacket _packetTmp; /* temp audio packet */
    
    AVRational outFrameAspectRatio;
    
    //dispatch queues
    dispatch_queue_t _pktWriteQueue;
    
    //semaphore to control stopping recorder
    dispatch_semaphore_t _semaWritePktsThread;
    
    //PTS & DTS values for Audio & Video packets to be written
    int64_t _oStartVPts;
    int64_t _oStartVDts;
    int64_t _oStartAPts;
    int64_t _oStartADts;
    
    int64_t _oLatestVPts;
    int64_t _oLatestVDts;
    int64_t _oLatestAPts;
    int64_t _oLatestADts;
    
    /* dts of the last packet sent to the muxer */
    int64_t _lastMuxADts;
    int64_t _lastMuxVDts;
    
    int _oVideo;
    int _oAudio;
    
    BOOL _isMJPEG;
    BOOL _isAppleHLS;
    
    int _activeAudioStreamId;
    int _activeVideoStreamId;
    
    AVBitStreamFilterContext *_bsfcAudio;
}

@end

@implementation VKRecorder

@synthesize timeMultiplierForMJPEG = _timeMultiplierForMJPEG;

#pragma mark - Initialization

- (id)initWithInputFormat:(AVFormatContext *)fmtCtx activeAudioStreamId:(int)aStreamId
      activeVideoStreamId:(int)vStreamId fullPathWithFileName:(NSString *)path {
    
    if (!fmtCtx) {
        VKLog(kVKLogLevelRecorder, @"Source stream is not found");
        return NULL;
    }
    
    self = [super init];
    if (self) {
        _state = kVKRecorderStateNone;
        _inputFmtCtx = fmtCtx;
        _activeAudioStreamId = aStreamId;
        _activeVideoStreamId = vStreamId;
        
        [self initValues];
        [self initPath:path];
        [self createDispatchQueues];
    }
    return self;
}

- (void)initValues {
    //initialize temp packet
    av_init_packet(&_packetTmp);
    
    //init primitives
    _oStartVPts = -1;
    _oStartVDts = -1;
    _oStartAPts = -1;
    _oStartADts = -1;
    
    _oLatestVPts = -1;
    _oLatestVDts = -1;
    _oLatestAPts = -1;
    _oLatestADts = -1;
    
    _oVideo = -1;
    _oAudio = -1;
    
    _isMJPEG = NO;
    
    if (_inputFmtCtx->iformat && _inputFmtCtx->iformat->name && strlen(_inputFmtCtx->iformat->name)) {
        NSString *fmtName = [NSString stringWithUTF8String:_inputFmtCtx->iformat->name];
        if ([fmtName rangeOfString:@"mjpeg"].location != NSNotFound) {
            _isMJPEG = YES;
        } else if ([fmtName rangeOfString:@"hls"].location != NSNotFound) {
            _isAppleHLS = YES;
        }
    }
    _timeMultiplierForMJPEG = 30;
    
    _bsfcAudio = NULL;
}

- (void)initPath:(NSString *)path {
    if (path && [path length]) {
        _recordPath = [path retain];
    } else {
        int movieIndex = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"movie_index"];
        NSString *name = @"movie";
        if (strlen(_inputFmtCtx->filename)) {
            NSString *streamPath = [[[NSString alloc] initWithUTF8String:_inputFmtCtx->filename] autorelease];
            NSString *lastComponent = [streamPath lastPathComponent];
            if (lastComponent && [lastComponent length] > 10) {
                name = [[streamPath lastPathComponent] substringToIndex:10];
            } else {
                name = [streamPath lastPathComponent];
            }
        }
        
        NSString *containerDefault = VK_RECORDING_DEFAULT_CONTAINER;
        
        if (_isAppleHLS && ([containerDefault caseInsensitiveCompare:@"mkv"] == NSOrderedSame)) {
            containerDefault = @"mp4";
            VKLog(kVKLogLevelRecorder, @"MKV container does not accept aac from hls stream, therefore container is changed from mkv to mp4");
        }
        
        NSString *fileName = [NSString stringWithFormat:@"(%d)%@.%@", movieIndex, name, containerDefault];
        _recordPath = [[NSString stringWithFormat:@"%@/%@",VK_RECORDING_DEFAULT_FOLDER_PATH, fileName] retain];
        [[NSUserDefaults standardUserDefaults] setInteger:(movieIndex+1) forKey:@"movie_index"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        VKLog(kVKLogLevelRecorder, @"Recording path: %@", _recordPath);
    }
}

- (void)createDispatchQueues {
    _pktWriteQueue = dispatch_queue_create("packet_write_queue", NULL);
}

#pragma mark - Actions

- (void)start {
    if (_state != kVKRecorderStateNone) {
        VKLog(kVKLogLevelRecorder, @"Recorder is already started");
        return;
    }
    
    VKErrorRecorder error = [self createOutputFormatAndContext];
    if (error != kVKErrorRecorderNone) {
        if (_delegate && [_delegate respondsToSelector:@selector(didStopRecordingWithRecorder:error:)]) {
            [_delegate didStopRecordingWithRecorder:self error:error];
        }
        return;
    }
    
    [self writePackets];
    
    if (_delegate && [_delegate respondsToSelector:@selector(didStartRecordingWithRecorder:)]) {
        [_delegate didStartRecordingWithRecorder:self];
    }
}

- (void)stop {
    _abortRequest = YES;
    [self unlockQueues];
    
    if (_semaWritePktsThread) {
        dispatch_semaphore_wait(_semaWritePktsThread, DISPATCH_TIME_FOREVER);
        dispatch_release(_semaWritePktsThread);
        _semaWritePktsThread = NULL;
    }
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
    
    if (!isFlushPkt) {
        AVStream *stream = _inputFmtCtx->streams[packet->stream_index];
        streamPkt.modifiedDts = av_rescale_q(packet->dts, stream->time_base, AV_TIME_BASE_Q);
        streamPkt.modifiedPts = av_rescale_q(packet->pts, stream->time_base, AV_TIME_BASE_Q);
        streamPkt.modifiedDuration = av_rescale_q(packet->duration, stream->time_base, AV_TIME_BASE_Q);
    } else {
        
    }
    [_pktQueue insertObject:streamPkt atIndex:0];
    [streamPkt release];
}

#pragma mark - private actions

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (VKErrorRecorder)createOutputFormatAndContext {
    
    VKErrorRecorder error = kVKErrorRecorderNone;
    int avError = 0;
    
    _outputFmt = NULL;
    _outputFmtCtx = NULL;
    
    //Allocate an output context for writing
    avError = avformat_alloc_output_context2(&_outputFmtCtx, NULL, NULL, [_recordPath UTF8String]);
    if (!_outputFmtCtx) {
        fprintf(stderr, "Could not create output context\n");
        error = kVKErrorRecorderOnInitialization;
        goto end;
    }
    
    //Copy streams from original stream
    _outputFmt = _outputFmtCtx->oformat;
    int idOutStream = 0;
    for (int idStrm = 0; idStrm < _inputFmtCtx->nb_streams; idStrm++) {
        if (idStrm == _activeAudioStreamId || idStrm == _activeVideoStreamId) {
            AVStream *in_stream = _inputFmtCtx->streams[idStrm];
            
            if (in_stream->codec->codec_type == AVMEDIA_TYPE_AUDIO ||
                in_stream->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
                AVStream *out_stream = avformat_new_stream(_outputFmtCtx, NULL);
                if (!out_stream) {
                    fprintf(stderr, "Failed allocating output stream\n");
                    error = kVKErrorRecorderOnInitialization;
                    goto end;
                }
                avcodec_get_context_defaults3(out_stream->codec, NULL);
                out_stream->codec->codec_type = in_stream->codec->codec_type;
                
                if (avError < 0) {
                    fprintf(stderr, "Failed to copy context from input to output stream codec context\n");
                    error = kVKErrorRecorderOnInitialization;
                    goto end;
                }
                
                [self initCodecWithStream:out_stream fromStream:in_stream];
                
                if (out_stream->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
                    _lastMuxVDts = AV_NOPTS_VALUE;
                    out_stream->first_dts = 0;
                    if (!out_stream->r_frame_rate.num)
                        out_stream->r_frame_rate = in_stream->r_frame_rate;
                    _oVideo = idOutStream++;
                } else if (out_stream->codec->codec_type == AVMEDIA_TYPE_AUDIO){
                    _lastMuxADts = AV_NOPTS_VALUE;
                    _oAudio = idOutStream++;
                    
                    if (_outputFmtCtx->oformat && _outputFmtCtx->oformat->extensions) {
                        NSString *container = [NSString stringWithUTF8String:_outputFmtCtx->oformat->extensions];
                        if ([container localizedCaseInsensitiveContainsString:@"mp4"]) {
                            if (!(_bsfcAudio = av_bitstream_filter_init("aac_adtstoasc"))) {
                                fprintf(stderr, "Failed to initialization of bitstream filter\n");
                                error = kVKErrorRecorderOnInitialization;
                                goto end;
                            }
                        }
                    }
                }
                
                if (_outputFmtCtx->oformat->flags & AVFMT_GLOBALHEADER)
                    out_stream->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
            }
        }
    }
    
    //dump the profile of copied streams in output context
    av_dump_format(_outputFmtCtx, 0, [_recordPath UTF8String], 1);
    
    //open the file that packets will be written
    if (!(_outputFmt->flags & AVFMT_NOFILE)) {
        avError = avio_open(&_outputFmtCtx->pb, [_recordPath UTF8String], AVIO_FLAG_READ_WRITE);
        if (avError < 0) {
            fprintf(stderr, "Could not open output file '%s'\n", [_recordPath UTF8String]);
            error = kVKErrorRecorderOnInitialization;
            goto end;
        }
    }
    
    //write the header of media file
    avError = avformat_write_header(_outputFmtCtx, NULL);
    if (avError < 0) {
        fprintf(stderr, "Error occurred when opening output file\n - error %s\n", av_err2str(avError));
        goto end;
    }
    return kVKErrorRecorderNone;
    
end:
    /* close output */
    if (_outputFmtCtx && !(_outputFmt->flags & AVFMT_NOFILE))
        avio_close(_outputFmtCtx->pb);
    avformat_free_context(_outputFmtCtx);
    if (avError < 0 && avError != AVERROR_EOF) {
        fprintf(stderr, "Error occurred: %s\n", av_err2str(avError));
        return 1;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(didStopRecordingWithRecorder:error:)]) {
        [_delegate didStopRecordingWithRecorder:self error:error];
    }
    
    return 0;
}

- (int)initCodecWithStream:(AVStream *)psout fromStream:(const AVStream *)sin {
    AVCodecContext *pccin = sin->codec;
    AVCodecContext *pccout = psout->codec;
    
    pccout->bits_per_raw_sample    = pccin->bits_per_raw_sample;
    pccout->chroma_sample_location = pccin->chroma_sample_location;
    
    AVRational sar;
    uint64_t extra_size;
    
    extra_size = (uint64_t)pccin->extradata_size + FF_INPUT_BUFFER_PADDING_SIZE;
    
    if (extra_size > INT_MAX)
        return AVERROR(EINVAL);
    
    /* if stream_copy is selected, no need to decode or encode */
    pccout->codec_id = pccin->codec_id;
    pccout->codec_type = pccin->codec_type;
    
    if (!pccout->codec_tag)
    {
        unsigned int codec_tag;
        if (!_outputFmtCtx->oformat->codec_tag ||
            av_codec_get_id(_outputFmtCtx->oformat->codec_tag, pccin->codec_tag) == pccout->codec_id ||
            !av_codec_get_tag2(_outputFmtCtx->oformat->codec_tag, pccin->codec_id, &codec_tag))
        {
            pccout->codec_tag = pccin->codec_tag;
        }
    }
    
    pccout->bit_rate       = pccin->bit_rate;
    pccout->rc_max_rate    = pccin->rc_max_rate;
    pccout->rc_buffer_size = pccin->rc_buffer_size;
    pccout->field_order    = pccin->field_order;
    pccout->extradata      = (uint8_t *)av_mallocz((size_t)extra_size);
    if (!pccout->extradata)
        return AVERROR(ENOMEM);
    
    memcpy(pccout->extradata, pccin->extradata, pccin->extradata_size);
    pccout->extradata_size= pccin->extradata_size;
    pccout->bits_per_coded_sample  = pccin->bits_per_coded_sample;
    
    pccout->time_base = sin->time_base;
    
    if (!strcmp(_outputFmtCtx->oformat->name, "avi"))
    {
        if (av_q2d(sin->r_frame_rate) >= av_q2d(sin->avg_frame_rate) &&
            0.5 / av_q2d(sin->r_frame_rate) > av_q2d(sin->time_base) &&
            0.5 / av_q2d(sin->r_frame_rate) > av_q2d(pccin->time_base) &&
            av_q2d(sin->time_base) < 1.0 / 500 &&
            av_q2d(pccin->time_base) < 1.0 / 500)
        {
            pccout->time_base.num = sin->r_frame_rate.den;
            pccout->time_base.den = 2 * sin->r_frame_rate.num;
            pccout->ticks_per_frame = 2;
        }
        else if (av_q2d(pccin->time_base) * pccin->ticks_per_frame > 2 * av_q2d(sin->time_base) &&
                 av_q2d(sin->time_base) < 1.0 / 500)
        {
            pccout->time_base = pccin->time_base;
            pccout->time_base.num *= pccin->ticks_per_frame;
            pccout->time_base.den *= 2;
            pccout->ticks_per_frame = 2;
        }
    }
    else if (!(_outputFmtCtx->oformat->flags & AVFMT_VARIABLE_FPS) &&
             strcmp(_outputFmtCtx->oformat->name, "mov") &&
             strcmp(_outputFmtCtx->oformat->name, "mp4") &&
             strcmp(_outputFmtCtx->oformat->name, "3gp") &&
             strcmp(_outputFmtCtx->oformat->name, "3g2") &&
             strcmp(_outputFmtCtx->oformat->name, "psp") &&
             strcmp(_outputFmtCtx->oformat->name, "ipod") &&
             strcmp(_outputFmtCtx->oformat->name, "f4v"))
    {
        if ((copy_tb < 0 && pccin->time_base.den
             && av_q2d(pccin->time_base) * pccin->ticks_per_frame > av_q2d(sin->time_base)
             && av_q2d(sin->time_base) < 1.0 / 500) ||
            copy_tb == 0)
        {
            pccout->time_base = pccin->time_base;
            pccout->time_base.num *= pccin->ticks_per_frame;
        }
    }
    
    av_reduce(&pccout->time_base.num, &pccout->time_base.den,
              pccout->time_base.num, pccout->time_base.den, INT_MAX);
    
    switch (pccout->codec_type)
    {
        case AVMEDIA_TYPE_AUDIO:
        {
            
            pccout->channel_layout     = pccin->channel_layout;
            pccout->sample_rate        = pccin->sample_rate;
            pccout->channels           = pccin->channels;
            pccout->frame_size         = pccin->frame_size;
            pccout->audio_service_type = pccin->audio_service_type;
            pccout->block_align        = pccin->block_align;
            pccout->block_align        = pccin->block_align;
            if((pccout->block_align == 1 || pccout->block_align == 1152 || pccout->block_align == 576) && pccout->codec_id == AV_CODEC_ID_MP3)
                pccout->block_align= 0;
            if(pccout->codec_id == AV_CODEC_ID_AC3)
                pccout->block_align= 0;
            break;
        }
            
        case AVMEDIA_TYPE_VIDEO:
        {
            pccout->pix_fmt            = pccin->pix_fmt;
            pccout->width              = pccin->width;
            pccout->height             = pccin->height;
            pccout->has_b_frames       = pccin->has_b_frames;
            
            if (outFrameAspectRatio.num)
            {
                // overridden by the -aspect cli option
                sar = av_mul_q(outFrameAspectRatio, (AVRational){ pccout->height, pccout->width });
                av_log(NULL,
                       AV_LOG_WARNING,
                       "overriding aspect ratio "
                       "with stream copy may produce invalid files\n");
            }
            else if (sin->sample_aspect_ratio.num)
            {
                sar = sin->sample_aspect_ratio;
            }
            else
            {
                sar = pccin->sample_aspect_ratio;
            }
            psout->sample_aspect_ratio = pccout->sample_aspect_ratio = sar;
            psout->avg_frame_rate = sin->avg_frame_rate;
        }
            break;
            
        default:
            exit(EXIT_FAILURE);
    }
    
    return 0;
}

- (void)writePackets {
    
    _semaWritePktsThread = dispatch_semaphore_create(0);
    __block VKErrorRecorder error = kVKErrorRecorderNone;
    __block int multiplierIter = 1;
    
    dispatch_async(_pktWriteQueue, ^(void) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        BOOL newPktRequired = NO;
        BOOL needsTSResetForAudio = NO;
        BOOL needsTSResetForVideo = NO;
        int pktSerial = 0;
        VKPacket *pkt;
        int countPkt = 0;
        pkt = nil;
        AVCodecContext *activeCodecCtx = NULL;
        
        for (;;) {
            
            [NSThread sleepForTimeInterval:0.01];
            
            if (_abortRequest)
                break;
            
            pthread_mutex_lock(&_mutexPkt);
            countPkt = (int)[_pktQueue count];
            if (!countPkt) {
                pthread_cond_wait(&_condPkt, &_mutexPkt);
                if (_abortRequest) {
                    pthread_mutex_unlock(&_mutexPkt);
                    break;
                }
            }
            pkt = (VKPacket *)[_pktQueue lastObject];
            
            if (pkt && (pkt.flush)) {
                _pktQueueSize = _pktQueueSize - pkt.size;
                [_pktQueue removeLastObject];
                newPktRequired = YES;
            }
            pthread_mutex_unlock(&_mutexPkt);
            
            if (newPktRequired) {
                newPktRequired = NO;
                needsTSResetForAudio = YES;
                needsTSResetForVideo = YES;
                continue;
                
            }
            
            if (pkt.streamIndex == _activeAudioStreamId) {
                
                if (needsTSResetForAudio) {
                    needsTSResetForAudio = NO;
                    
                    if (_oLatestADts != -1) {
                        _oStartADts = pkt.modifiedDts - _oLatestADts;
                    }
                    
                    if (_oLatestAPts != -1) {
                        _oStartAPts =pkt.modifiedPts - _oLatestAPts;
                    }
                }
                
                if (_oStartADts < 0)
                    _oStartADts = pkt.modifiedDts;
                
                _oLatestADts = pkt.modifiedDts;
                
                pkt.modifiedDts = av_rescale_q_rnd((pkt.modifiedDts - _oStartADts), AV_TIME_BASE_Q,
                                                   _outputFmtCtx->streams[_oAudio]->time_base, (AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX));
                
                if (_oStartAPts < 0)
                    _oStartAPts = pkt.modifiedPts;
                
                _oLatestAPts = pkt.modifiedPts;
                pkt.modifiedPts = av_rescale_q_rnd((pkt.modifiedPts - _oStartAPts), AV_TIME_BASE_Q,
                                                   _outputFmtCtx->streams[_oAudio]->time_base, (AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX));
                
                pkt.modifiedDuration = av_rescale_q(pkt.modifiedDuration, AV_TIME_BASE_Q, _outputFmtCtx->streams[_oAudio]->time_base);
                _packetTmp.stream_index = _oAudio;
                
                activeCodecCtx = _outputFmtCtx->streams[_oAudio]->codec;
            } else if (pkt.streamIndex == _activeVideoStreamId) {
                
                if (needsTSResetForVideo) {
                    needsTSResetForVideo = NO;
                    if (_oLatestVDts != -1) {
                        _oStartVDts = pkt.modifiedDts - _oLatestVDts;
                    }
                    
                    if (_oLatestVPts != -1) {
                        _oStartVPts = pkt.modifiedPts - _oLatestVPts;
                    }
                }
                
                if (_oAudio != -1) {
                    if (_oStartADts < 0) {
                        pthread_mutex_lock(&_mutexPkt);
                        _pktQueueSize = _pktQueueSize - pkt.size;
                        [_pktQueue removeLastObject];
                        pthread_mutex_unlock(&_mutexPkt);
                        continue;
                    }
                    
                    if (_oStartVDts < 0)
                        _oStartVDts = _oStartADts;
                    
                    if (_oStartVPts < 0)
                        _oStartVPts = _oStartAPts;
                    
                } else {
                    if (_oStartVDts < 0)
                        _oStartVDts = pkt.modifiedDts;
                    
                    if (_oStartVPts < 0)
                        _oStartVPts = pkt.modifiedPts;
                }
                
                _oLatestVDts = pkt.modifiedDts;
                
                pkt.modifiedDts = av_rescale_q_rnd((pkt.modifiedDts - _oStartVDts), AV_TIME_BASE_Q,
                                                   _outputFmtCtx->streams[_oVideo]->time_base, (AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX));
                
                if (_oStartVPts < 0)
                    _oStartVPts = _oStartAPts;
                
                _oLatestVPts = pkt.modifiedPts;
                
                pkt.modifiedPts = av_rescale_q_rnd((pkt.modifiedPts - _oStartVPts), AV_TIME_BASE_Q,
                                                   _outputFmtCtx->streams[_oVideo]->time_base, (AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX));
                
                pkt.modifiedDuration = av_rescale_q(pkt.modifiedDuration, AV_TIME_BASE_Q, _outputFmtCtx->streams[_oVideo]->time_base);
                
                if (_isMJPEG && pkt.modifiedPts) {
                    pkt.modifiedPts += _timeMultiplierForMJPEG * multiplierIter * pkt.modifiedDuration;
                    pkt.modifiedDts += pkt.modifiedDuration;
                    multiplierIter ++;
                }
                _packetTmp.stream_index = _oVideo;
                
                activeCodecCtx = _outputFmtCtx->streams[_oVideo]->codec;
            }
            
            _packetTmp.data = pkt ? (uint8_t *)[pkt.samples bytes] : NULL;
            _packetTmp.size = pkt.size;
            _packetTmp.pts = pkt.modifiedPts;
            _packetTmp.dts = pkt.modifiedDts;
            _packetTmp.duration = (int)pkt.modifiedDuration;
            _packetTmp.flags = pkt.flags;
            _packetTmp.pos = pkt.pos;
            
            if (_bsfcAudio) {
                
                AVStream *stream = _outputFmtCtx->streams[_oAudio];
                AVCodecContext *avctx = stream->codec;
                
                int a = av_bitstream_filter_filter(_bsfcAudio, avctx, NULL,
                                                   &_packetTmp.data, &_packetTmp.size,
                                                   _packetTmp.data, _packetTmp.size,
                                                   pkt.flags & AV_PKT_FLAG_KEY);
                if(a == 0 && _packetTmp.data != _packetTmp.data) {
                    error = kVKErrorRecorderOnWriting;
                    VKLog(kVKLogLevelRecorder, @"Bitstream filter data not equal error during muxing packet");
                    break;
                } else if (a < 0) {
                    error = kVKErrorRecorderOnWriting;
                    VKLog(kVKLogLevelRecorder, @"Bitstream filter open error during muxing packet");
                    break;
                }
            }
            if (!(_outputFmtCtx->oformat->flags & AVFMT_NOTIMESTAMPS) &&
                _packetTmp.dts != AV_NOPTS_VALUE) {
                
                BOOL increaseDTS = NO;
                int64_t max = 0;
                
                if (activeCodecCtx->codec_type == AVMEDIA_TYPE_AUDIO) {
                    if (_lastMuxADts != AV_NOPTS_VALUE) {
                        max = _lastMuxADts + !(_outputFmtCtx->oformat->flags & AVFMT_TS_NONSTRICT);
                        VKLog(kVKLogLevelRecorder, @"max:%lld, _lastMuxADts:%lld", max, _lastMuxADts);
                        increaseDTS = YES;
                    }
                } else if (activeCodecCtx->codec_type == AVMEDIA_TYPE_VIDEO) {
                    if (_lastMuxVDts != AV_NOPTS_VALUE) {
                        max = _lastMuxVDts + !(_outputFmtCtx->oformat->flags & AVFMT_TS_NONSTRICT);
                        VKLog(kVKLogLevelRecorder, @"max:%lld, _lastMuxVDts:%lld", max, _lastMuxVDts);
                        increaseDTS = YES;
                    }
                }
                
                if (increaseDTS) {
                    if (_packetTmp.dts < max) {
                        VKLog(kVKLogLevelRecorder, @"Non-monotonous DTS in output stream - fixed");
                        
                        if(_packetTmp.pts >= _packetTmp.dts)
                            _packetTmp.pts = FFMAX(_packetTmp.pts, max);
                        _packetTmp.dts = max;
                    }
                }
            }
            
            NSString *packetType = @"AVMEDIA_TYPE_UNKNOWN";
            if (activeCodecCtx->codec_type == AVMEDIA_TYPE_AUDIO) {
                _lastMuxADts = _packetTmp.dts;
                packetType = @"AVMEDIA_TYPE_AUDIO";
            } else if (activeCodecCtx->codec_type == AVMEDIA_TYPE_VIDEO) {
                _lastMuxVDts = _packetTmp.dts;
                packetType = @"AVMEDIA_TYPE_VIDEO";
            }
            
            pktSerial = pkt.serial;
            int pktSize = _packetTmp.size;
            
            int ret = av_interleaved_write_frame(_outputFmtCtx, &_packetTmp);
            if (ret < 0) {
                error = kVKErrorRecorderOnWriting;
                VKLog(kVKLogLevelRecorder, @"Error muxing packet - packetType:%@", packetType);
                break;
            } else {
                float bytesInKB = (float)(pktSize)/1000.0;
                VKLog(kVKLogLevelRecorder, @"Pkt (size = %0.2f KB)is written successfully", bytesInKB);
            }
            
            pthread_mutex_lock(&_mutexPkt);
            _pktQueueSize = _pktQueueSize - pktSize;
            [_pktQueue removeLastObject];
            pthread_mutex_unlock(&_mutexPkt);
            
        }
        
        //write the movie file trailer
        av_write_trailer(_outputFmtCtx);
        
        // close output
        if (_outputFmtCtx && !(_outputFmt->flags & AVFMT_NOFILE)) {
            avio_close(_outputFmtCtx->pb);
        }
        avformat_free_context(_outputFmtCtx);
        
        dispatch_semaphore_signal(_semaWritePktsThread);
        [pool release];
        
        if (error == kVKErrorRecorderNone) {
            if (_delegate && [_delegate respondsToSelector:@selector(didStopRecordingWithRecorder:error:)]) {
                [_delegate didStopRecordingWithRecorder:self error:error];
            }
        } else {
            if (_delegate && [_delegate respondsToSelector:@selector(didStopRecordingWithRecorder:error:)]) {
                [_delegate didStopRecordingWithRecorder:self error:error];
            }
        }
    });
}

#pragma clang diagnostic pop

#pragma mark - Memory deallocation

- (void)dealloc {
    [_recordPath release];
    [super dealloc];
}


@end
