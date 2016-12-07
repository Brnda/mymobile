//
//  VKAudioDecoder.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "VKAudioDecoder.h"
#import "VKPacket.h"

//defines
/* we use about AUDIO_DIFF_AVG_NB A-V differences to make the average */
#define AUDIO_DIFF_AVG_NB   20
#define AUDIO_S16SYS        0x8010	/**< Signed 16-bit samples */

#define OUTPUT_BUS              0
#define MAX_AU_BUFFER_SIZE      1024
#define ERROR_HERE(status) do {if (status) fprintf(stderr, "ERROR %d [%s:%u]\n", (int)status, __func__, __LINE__);}while(0);

//Audio structs
typedef struct AudioParams {
    int freq;
    int channels;
    int64_t channelLayout;
    enum AVSampleFormat fmt;
} AudioParams;


//Audio functions
static OSStatus auMixerCallback(void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags,
                  const AudioTimeStamp        *inTimeStamp, UInt32                       inBusNumber,
                  UInt32                       inNumberFrames, AudioBufferList             *ioData);

@interface VKAudioDecoder() {
    
    AVFormatContext* _avFmtCtx; /* avformat context reference */
    
    NSMutableData *_rawData; /* raw audio data */
    AVFrame *_frame; /* audio frame */
    AVPacket _packetTmp; /* temp audio packet */
    
    //AV syncing
    int64_t _callbackTime;
    int64_t _frameNextPts;
    
    double _clock;
    int _clockSerial;
    
    int _hwBufSize;
    unsigned int _bufSize; /* in bytes */
    unsigned int _bufIndex; /* in bytes */
    int _writeBufSize;
    
    double _diffCum; /* used for AV difference average computation */
    double _diffAvgCoef;
    double _diffThreshold;
    int _diffAvgCount;

    //Audio resampling
    struct AudioParams _sourceParams;
    struct AudioParams _targetParams;
    struct SwrContext *_swrCtx;
    uint8_t *_swrBufferTemp;
    unsigned int _sizeSwrBufferTemp; /* in bytes */

    int64_t _currentPos;
    BOOL _eof;
    float _volumeLevel;
    float _panningLevel;
    
    //AUGraph
    AUGraph   _mGraph;
    AudioUnit _mMixer;
    
    int _nbChannels;
    int _finished;
}

@end

@implementation VKAudioDecoder

@synthesize isWaitingForPackets = _waitingForPackets;
@synthesize currentPos = _currentPos;
@synthesize volumeLevel = _volumeLevel;
@synthesize panningLevel = _panningLevel;

- (id)initWithFormatContext:(AVFormatContext*)avFmtCtx codecContext:(AVCodecContext*)cdcCtx stream:(AVStream *)strm streamId:(NSInteger)sId manager:(id)manager {
    self = [super initWithCodecContext:cdcCtx stream:strm streamId:sId manager:manager];
    if (self) {
        _rawData = [[NSMutableData alloc] init];
        
        if (_ffmpegVersMajor > 1) {
            _frame = av_frame_alloc();
        } else {
            //_frame = avcodec_alloc_frame();
        }
        
        memset(&_packetTmp, 0, sizeof(_packetTmp));
        
        if (!_frame) {
            return nil;
        }
        [self initValues];
        
        _avFmtCtx = avFmtCtx;
    }
    return self;
}

- (void)initValues {
    
    _nbChannels = 2;
    int64_t channelLayout = 0;
    
    _hwBufSize = (AUDIO_S16SYS & 0xFF) / 8;
    _hwBufSize *= _nbChannels;
    _hwBufSize *= MAX_AU_BUFFER_SIZE;
    
    _sourceParams.fmt = AV_SAMPLE_FMT_S16;
    _sourceParams.channelLayout = av_get_default_channel_layout(_codecContext->channels);
    _sourceParams.channels = _codecContext->channels;
    _sourceParams.freq = _codecContext->sample_rate;
    
    /* iOS devices can not play more than 2 channels */
    channelLayout = av_get_default_channel_layout(_nbChannels);
    channelLayout &= ~AV_CH_LAYOUT_STEREO_DOWNMIX;
        
    _sourceParams.channels = av_get_channel_layout_nb_channels(channelLayout);
    _sourceParams.channelLayout = channelLayout;
    
    _targetParams = _sourceParams;

    _bufSize = 0;
    _bufIndex = 0;
    
    /* init averaging filter */
    _diffAvgCoef  = exp(log(0.01) / AUDIO_DIFF_AVG_NB);
    _diffAvgCount = 0;
    /* since we do not have a precise anough audio fifo fullness,
     we correct audio sync only if larger than this threshold */
    _diffThreshold = 2.0 * _hwBufSize / av_samples_get_buffer_size(NULL, _targetParams.channels, _targetParams.freq, _targetParams.fmt, 1);

    _clock = 0.0;
    _clockSerial = -1;
    
    _waitingForPackets = NO;
    _eof = NO;

    _volumeLevel = 1.0;
    _panningLevel = 0.0;
    
    _frameNextPts = 0;
}

#pragma mark AV syncing

- (int)syncAudio:(int)nb_samples {
    int wantedNumberOfSamples = nb_samples;
    return wantedNumberOfSamples;
}

#pragma mark - On State change actions

- (void)setEOF:(BOOL)value {
    _eof = value;
}

- (void)setVolumeLevel:(float)volumeLevel {
    if (volumeLevel != _volumeLevel) {
        _volumeLevel = volumeLevel;
        AudioUnitSetParameter(_mMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, _volumeLevel, 0);
    }
}

- (void)setPanningLevel:(float)panningLevel {
    if (panningLevel != _panningLevel) {
        _panningLevel = panningLevel;
        AudioUnitSetParameter(_mMixer, kMultiChannelMixerParam_Pan, kAudioUnitScope_Input, 0, _panningLevel, 0);
    }
}

#pragma mark - AUGraph

- (void)startAUGraph {
    if (_mGraph) {
        OSStatus result = AUGraphStart(_mGraph);
        ERROR_HERE(result);
    }
}

- (void)stopAUGraph {
    if (_mGraph) {
        Boolean isRunning = NO;
        OSStatus result = AUGraphIsRunning(_mGraph, &isRunning);
        if (isRunning) {
            result = AUGraphStop(_mGraph);
            ERROR_HERE(result);
        }
    }
}

- (void)startAudioSystem {
    // Setup the AUGraph, add AUNodes, and make connections ***

    // Error checking result
    OSStatus result = noErr;
    
    // create a new AUGraph
    result = NewAUGraph(&_mGraph);
    ERROR_HERE(result);
    
    // AUNodes represent AudioUnits on the AUGraph and provide an
    // easy means for connecting audioUnits together.
    AUNode outputNode;
    AUNode mixerNode;
    
    // Create AudioComponentDescriptions for the AUs
    // mixer component
    AudioComponentDescription mixerDesc;
    mixerDesc.componentType = kAudioUnitType_Mixer;
    mixerDesc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixerDesc.componentFlags = 0;
    mixerDesc.componentFlagsMask = 0;
    mixerDesc.componentManufacturer = kAudioUnitManufacturer_Apple;

    //remote IO
	AudioComponentDescription ioDesc;
	ioDesc.componentType          = kAudioUnitType_Output;
	ioDesc.componentSubType       = kAudioUnitSubType_RemoteIO;
	ioDesc.componentFlags         = 0;
	ioDesc.componentFlagsMask     = 0;
	ioDesc.componentManufacturer  = kAudioUnitManufacturer_Apple;
    
    // Add nodes to the graph to hold our AudioUnits,
    result = AUGraphAddNode(_mGraph, &ioDesc, &outputNode);
    ERROR_HERE(result);
    
    result = AUGraphAddNode(_mGraph, &mixerDesc, &mixerNode );
    ERROR_HERE(result);
    
    // Connect the mixer node's output to the output node's input
    AudioUnitElement mixerUnitOutputBus  = 0;
    AudioUnitElement ioUnitOutputElement = 0;
    result = AUGraphConnectNodeInput(_mGraph, mixerNode, mixerUnitOutputBus, outputNode, ioUnitOutputElement);
    ERROR_HERE(result);
    
    // open the graph AudioUnits
    result = AUGraphOpen(_mGraph);
    ERROR_HERE(result);
    
    // Get a link to the mixer AU
    result = AUGraphNodeInfo(_mGraph, mixerNode, NULL, &_mMixer);
    ERROR_HERE(result);
    
    //Make connections to the mixer unit's inputs
    UInt32 numbuses = 1;
    UInt32 size = sizeof(numbuses);
    result = AudioUnitSetProperty(_mMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &numbuses, size);
    ERROR_HERE(result);
    
    //CAStreamBasicDescription streamDesc;
    AudioStreamBasicDescription audioFormat;
    
    // Loop through and setup a callback for each source
    for (int i = 0; i < numbuses; ++i) {
        
        // Setup render callback struct to provide audio samples for the mixer unit.
        AURenderCallbackStruct renderCallbackStruct;
        renderCallbackStruct.inputProc = &auMixerCallback;
        renderCallbackStruct.inputProcRefCon = self;
        
        // Set a callback for the specified node's specified input
        result = AUGraphSetNodeInputCallback(_mGraph, mixerNode, i, &renderCallbackStruct);
        ERROR_HERE(result);
        
        // Get a AudioBasicDescription from the mixer bus.
        size = sizeof(audioFormat);
        result = AudioUnitGetProperty(_mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input,
                                      i, &audioFormat, &size);
        ERROR_HERE(result);
        
        // Initializes the structure to 0 to ensure there are no spurious values.
        memset (&audioFormat, 0, sizeof (audioFormat));
        
        audioFormat.mFormatID         = kAudioFormatLinearPCM;
        audioFormat.mSampleRate       = _sourceParams.freq;
        audioFormat.mChannelsPerFrame = _sourceParams.channels;
        audioFormat.mBitsPerChannel   = 16;
        audioFormat.mFramesPerPacket  = 1;
        audioFormat.mBytesPerFrame    = audioFormat.mChannelsPerFrame * audioFormat.mBitsPerChannel/8;
        audioFormat.mBytesPerPacket   = audioFormat.mBytesPerFrame * audioFormat.mFramesPerPacket;
        audioFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        
        // Apply the AudioStreamBasicDescription to the mixer input bus
        result = AudioUnitSetProperty(_mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i,
                                      &audioFormat, sizeof(audioFormat));
        ERROR_HERE(result);
    }
    
    // Apply the AudioStreamBasicDescription to the mixer output bus
    result = AudioUnitSetProperty(_mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output,
                                  0, &audioFormat, sizeof(audioFormat));
    ERROR_HERE(result);
    
    [self setVolumeLevel:[(VKDecodeManager *)_manager volumeLevel]];
    [self setPanningLevel:[(VKDecodeManager *)_manager panningLevel]];
    
    // Once everything is set up call initialize to validate connections
    result = AUGraphInitialize(_mGraph);
    ERROR_HERE(result);
    
    [self startAUGraph];
}

#pragma clang diagnostic pop

#pragma mark AU stop

- (void)stopAudioSystem {
    if (_mGraph) {
        [self stopAUGraph];
        
        OSStatus result = DisposeAUGraph(_mGraph);
        ERROR_HERE(result);
    }
}

#pragma mark AU Callback

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (OSStatus)auMixerCallback:(AudioUnitRenderActionFlags *)ioActionFlags
                     timestamp:(const AudioTimeStamp       *)inTimeStamp
                     busNumber:(UInt32                      )inBusNumber
                  numberFrames:(UInt32                      )inNumberFrames
                          data:(AudioBufferList            *)ioData
{
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    uint16_t *buffer = (uint16_t *)ioData->mBuffers[0].mData;
    int wantedNumberOfSamples;
    BOOL newPktRequired = NO;
    int pktSerial = 0;
    _callbackTime = av_gettime();
    AVRational tb;

start: ;
    
    int size = 0;
    int sizeOfPktProcessed;
    int64_t decChannelLayout;
    int lenSwr;

    VKPacket *pkt;
    int countPkt = 0;
    pkt = nil;

    if (!_abortRequest) {
        pthread_mutex_lock(&_mutexPkt);
        countPkt = (int)[_pktQueue count];
        
        if ((!countPkt && !_eof) ||
            (_waitingForPackets && countPkt < [(VKDecodeManager *)_manager minFramesToStartPlaying])) {
            
            _waitingForPackets = YES;
            if ([(VKDecodeManager *)_manager masterSyncType] == AV_SYNC_AUDIO_MASTER) {
                NSDictionary *data = @{@"state": @(kVKDecoderStateBuffering), @"error": @(kVKErrorNone)};
                [(VKDecodeManager *)_manager performSelector:@selector(setDecoderStateWithData:)
                                                    onThread:[NSThread currentThread] withObject:data waitUntilDone:YES];
            }
            pthread_mutex_unlock(&_mutexPkt);
            
            _bufSize = ioData->mBuffers[0].mDataByteSize;
            _bufIndex = 0;
            for (UInt32 i=0; i < ioData->mNumberBuffers; i++){
                memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
            }
            *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
            
            [pool release];
            
            return noErr;
            
        } else {
            _waitingForPackets = NO;
            
            if (![(VKDecodeManager *)_manager streamIsPaused]) {
                if ([(VKDecodeManager *)_manager masterSyncType] == AV_SYNC_AUDIO_MASTER) {
                    NSDictionary *data = @{@"state": @(kVKDecoderStatePlaying), @"error": @(kVKErrorNone)};
                    [(VKDecodeManager *)_manager performSelector:@selector(setDecoderStateWithData:)
                                                        onThread:[NSThread currentThread] withObject:data waitUntilDone:YES];
                }
            }
        }
        
        pkt = (VKPacket *)[_pktQueue lastObject];

        if (pkt && (_queueSerial != pkt.serial)) {
            /* the serial is updated (audio stream may be changed or seek process is done),
             drop packet to get a new one */
            _pktQueueSize = _pktQueueSize - pkt.size;
            [_pktQueue removeLastObject];
            newPktRequired = YES;
        }

        if (pkt && (pkt.flush)) {
            avcodec_flush_buffers(_codecContext);
            _frameNextPts = AV_NOPTS_VALUE;
            if ((_avFmtCtx->iformat->flags & (AVFMT_NOBINSEARCH | AVFMT_NOGENSEARCH | AVFMT_NO_BYTE_SEEK)) &&
                !_avFmtCtx->iformat->read_seek) {
                _frameNextPts = _stream->start_time;
            }
            _pktQueueSize = _pktQueueSize - pkt.size;
            [_pktQueue removeLastObject];
            newPktRequired = YES;
        }
        pthread_mutex_unlock(&_mutexPkt);
    }

    if (newPktRequired) {
        newPktRequired = NO;
        goto start;
    }

    int sizeMData = ioData->mBuffers[0].mDataByteSize;
    int maxBytes = sizeMData;

    _packetTmp.data = pkt ? (uint8_t *)[pkt.samples bytes] : NULL;
    _packetTmp.size = pkt.size;
    _packetTmp.pts = pkt.pts;
    _packetTmp.dts = pkt.dts;
    _packetTmp.flags = pkt.flags;
    _packetTmp.pos = pkt.pos;
    _packetTmp.duration = pkt.duration;
    
    _currentPos =  _packetTmp.pos;
    pktSerial = pkt.serial;

    if (!_abortRequest && !_packetTmp.data) {
        goto fail;
    }

    int dataSize;
    int gotFrame;

    int bytesPerSec = 0;

    if ([(VKDecodeManager *)_manager streamIsPaused] ||
        _abortRequest) {
        _bufSize = maxBytes;
        _bufIndex = 0;
        for (UInt32 i=0; i < ioData->mNumberBuffers; i++){
            memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
        }
        *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;

        goto success;
    }
    
    if ([_rawData length] < maxBytes) {

        int pktSize = _packetTmp.size;

        while (_packetTmp.size > 0) {

            uint8_t *framePtr;
            
            if (_ffmpegVersMajor > 1) {
                av_frame_unref(_frame);
            } else {
                //avcodec_get_frame_defaults(_frame);
            }
            
            sizeOfPktProcessed = avcodec_decode_audio4(_codecContext, _frame, &gotFrame, &_packetTmp);
            if (sizeOfPktProcessed < 0) {
                goto restart;
            }
            
            _packetTmp.dts = _packetTmp.pts = AV_NOPTS_VALUE;
            _packetTmp.data += sizeOfPktProcessed;
            _packetTmp.size -= sizeOfPktProcessed;
            
            int reset = 0;
            if ((_packetTmp.data && _packetTmp.size <= 0) || (!_packetTmp.data && !gotFrame)) {
                reset = 1;
            }
            
            if (!_packetTmp.data && !gotFrame) {
                _finished = pkt.serial;
            }
            
            if (!gotFrame) {
                if (reset) {
                    goto restart;
                }
                continue;
            }
            tb = (AVRational){ 1, _frame->sample_rate };
            if (_frame->pts != AV_NOPTS_VALUE)
                _frame->pts = av_rescale_q(_frame->pts, _codecContext->time_base, tb);
            else if (_frame->pkt_pts != AV_NOPTS_VALUE)
                _frame->pts = av_rescale_q(_frame->pkt_pts, _stream->time_base, tb);
            else if (_frameNextPts != AV_NOPTS_VALUE)
                _frame->pts = av_rescale_q(_frameNextPts, (AVRational){ 1, _sourceParams.freq }, tb);
            
            if (_frame->pts != AV_NOPTS_VALUE)
                _frameNextPts = _frame->pts + _frame->nb_samples;
            
            size = av_samples_get_buffer_size(NULL, av_frame_get_channels(_frame),
                                              _frame->nb_samples,
                                              _frame->format, 1);

            decChannelLayout = (_frame->channel_layout && av_frame_get_channels(_frame) == av_get_channel_layout_nb_channels(_frame->channel_layout)) ?
            _frame->channel_layout : av_get_default_channel_layout(av_frame_get_channels(_frame));
            wantedNumberOfSamples = [self syncAudio:_frame->nb_samples];

            if (_frame->format           != _sourceParams.fmt ||
                decChannelLayout         != _sourceParams.channelLayout ||
                _frame->sample_rate      != _sourceParams.freq          ||
                (wantedNumberOfSamples       != _frame->nb_samples && !_swrCtx)) {
                
                swr_free(&_swrCtx);
                _swrCtx = swr_alloc_set_opts(NULL, _targetParams.channelLayout, _targetParams.fmt, _targetParams.freq, decChannelLayout, _frame->format, _frame->sample_rate, 0, NULL);
                if (!_swrCtx || swr_init(_swrCtx) < 0) {
                    VKLog(kVKLogLevelDecoderExtra, @"Cannot create sample rate converter for conversion of %d Hz %s %d channels to %d Hz %s %d channels!\n",
                          _frame->sample_rate, av_get_sample_fmt_name(_frame->format), av_frame_get_channels(_frame),
                          _targetParams.freq, av_get_sample_fmt_name(_targetParams.fmt), _targetParams.channels);
                    goto fail;
                }
                _sourceParams.channelLayout = decChannelLayout;
                _sourceParams.channels = av_frame_get_channels(_frame);
                _sourceParams.freq = _frame->sample_rate;
                _sourceParams.fmt = _frame->format;
            }


            if (_swrCtx) {
                const uint8_t **in = (const uint8_t **)_frame->extended_data;
                uint8_t **out = &_swrBufferTemp;
                long long out_count = (int64_t)wantedNumberOfSamples * _targetParams.freq / _frame->sample_rate + 256;
                long long out_size  = av_samples_get_buffer_size(NULL, _targetParams.channels, (int)out_count, _targetParams.fmt, 0);
                if (wantedNumberOfSamples != _frame->nb_samples) {
                    if (swr_set_compensation(_swrCtx, (wantedNumberOfSamples - _frame->nb_samples) * _targetParams.freq / _frame->sample_rate,
                                             wantedNumberOfSamples * _targetParams.freq / _frame->sample_rate) < 0) {
                        fprintf(stderr, "swr_set_compensation() failed\n");
                        goto fail;
                    }
                }
                av_fast_malloc(&_swrBufferTemp, &_sizeSwrBufferTemp, (size_t)out_size);
                if (!_swrBufferTemp) {
                    VKLog(kVKLogLevelDecoderExtra, @"swrBufferTemp %d", AVERROR(ENOMEM));
                    goto fail;
                }
                
                lenSwr = swr_convert(_swrCtx, out, (int)out_count, in, _frame->nb_samples);
                if (lenSwr < 0) {
                    VKLog(kVKLogLevelDecoderExtra, @"swr_convert() failed");
                    goto fail;
                }
                if (lenSwr == out_count) {
                    VKLog(kVKLogLevelDecoderExtra, @"warning: audio buffer is probably too small");
                    swr_init(_swrCtx);
                }
                framePtr = _swrBufferTemp;
                _bufSize = lenSwr * _targetParams.channels * av_get_bytes_per_sample(_targetParams.fmt);
            } else {
                framePtr = _frame->data[0];
                _bufSize = size;
            }
            
            /* update the audio clock with the pts */
            if (_frame->pts != AV_NOPTS_VALUE)
                _clock = _frame->pts * av_q2d(tb) + (double) _frame->nb_samples / _frame->sample_rate;
            else
                _clock = NAN;
            
            _clockSerial = pktSerial;
            
            _bufIndex = 0;

            if (size < 0) {
                goto fail;
            }
            
            [_rawData appendBytes: (int16_t *)framePtr length:_bufSize];
        }

        pthread_mutex_lock(&_mutexPkt);
        if (pktSerial == _queueSerial) {
            _pktQueueSize = _pktQueueSize - pktSize;
            [_pktQueue removeLastObject];
        }
        pthread_mutex_unlock(&_mutexPkt);
    }

    int dataLength = (int)[_rawData length];

    if(dataLength >= maxBytes) {
        dataSize = maxBytes;
    } else {
        goto start;
    }

    _bufIndex += dataSize;
    memcpy(buffer, (uint16_t *)[_rawData mutableBytes], dataSize);
    [_rawData replaceBytesInRange:NSMakeRange(0, dataSize) withBytes:NULL length:0];
    
    goto success;
    
    
restart:
    
    pthread_mutex_lock(&_mutexPkt);
    if ([_pktQueue count]) {
        _pktQueueSize = _pktQueueSize - _packetTmp.size;
        [_pktQueue removeLastObject];
    }
    pthread_mutex_unlock(&_mutexPkt);
    
    goto start;

fail:

    pthread_mutex_lock(&_mutexPkt);
    if ([_pktQueue count]) {
        _pktQueueSize = _pktQueueSize - _packetTmp.size;
        [_pktQueue removeLastObject];
    }
    pthread_mutex_unlock(&_mutexPkt);


    _bufSize = maxBytes;
    _bufIndex = 0;
    for (UInt32 i=0; i < ioData->mNumberBuffers; i++){
        memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
    }
    
success:

    bytesPerSec = _targetParams.freq * _targetParams.channels * av_get_bytes_per_sample(_targetParams.fmt);
    _writeBufSize = _bufSize - _bufIndex;
    
    if (!isnan(_clock)) {
        [_clockManager setTime:(_callbackTime / 1000000.0) pts:(_clock - (double)(2 * _hwBufSize + _writeBufSize) / bytesPerSec)
                        serial:_clockSerial clock:_decoderClock];
        [_clockManager syncClockToSlave:[(VKDecodeManager *)_manager externalClock] slave:_decoderClock];
    }
    
    [pool release];

    return noErr;
}

OSStatus
auMixerCallback(void                        *inRefCon,
                  AudioUnitRenderActionFlags  *ioActionFlags,
                  const AudioTimeStamp        *inTimeStamp,
                  UInt32                       inBusNumber,
                  UInt32                       inNumberFrames,
                  AudioBufferList             *ioData)
{
    VKAudioDecoder *decoder = (VKAudioDecoder*)inRefCon;
    return [decoder auMixerCallback:ioActionFlags
                       timestamp:inTimeStamp
                       busNumber:inBusNumber
                    numberFrames:inNumberFrames
                            data:ioData];
}


#pragma mark - Shutdown

- (void)shutdown {

    [self unlockQueues];

    if (_streamId >= 0) {
		_stream->discard = AVDISCARD_ALL;
	}

    [self stopAudioSystem];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (_swrCtx)
        swr_free(&_swrCtx);

    if (_swrBufferTemp) {
        av_freep(&_swrBufferTemp);
        _swrBufferTemp = 0;
    }

    if (_codecContext) {
        avcodec_close(_codecContext);
    }
    if (_frame) {
        av_free(_frame);
    }
    [self clearPktQueue];
}

- (void)unlockQueues {    
    [super unlockQueues];
}

- (void)dealloc {
    VKLog(kVKLogLevelDecoderExtra, @"Audio Decoder is deallocated...");
    [_rawData release];
    [super dealloc];
}

@end
