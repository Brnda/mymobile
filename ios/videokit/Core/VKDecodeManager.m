//
//  VKDecodeManager.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "VKDecodeManager.h"
#import "VKAudioDecoder.h"
#import "VKVideoDecoder.h"
#import "VKClock.h"
#ifdef VK_RECORDING_CAPABILITY
#import "VKRecorder.h"
#endif
#import "VKReachability.h"

#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/opt.h>
#include "cmdutils.h"
#include <libavformat/rtsp.h>

#if !TARGET_OS_TV
#include <libavcodec/videotoolbox.h>
#endif

const char program_name[] = "VideoKit";
const int program_birth_year = 2013;

// VKDecoder decode option keys
NSString *VKDECODER_OPT_KEY_RTSP_TRANSPORT                      = @"rtsp_transport";
NSString *VKDECODER_OPT_KEY_AUD_STRM_DEF_IDX                    = @"audio_stream_default_index";
NSString *VKDECODER_OPT_KEY_AUD_STRM_DEF_STR                    = @"audio_stream_default_str";
NSString *VKDECODER_OPT_KEY_FORCE_MJPEG                         = @"force_mjpeg";
NSString *VKDECODER_OPT_KEY_PASS_THROUGH                        = @"pass_through";
NSString *VKDECODER_OPT_KEY_CACHE_STREAM_ENABLE                 = @"enable_cache_stream";


// VKDecoder decode option values
NSString *VKDECODER_OPT_VALUE_RTSP_TRANSPORT_UDP                = @"udp";
NSString *VKDECODER_OPT_VALUE_RTSP_TRANSPORT_TCP                = @"tcp";
NSString *VKDECODER_OPT_VALUE_RTSP_TRANSPORT_UDP_MULTICAST      = @"udp_multicast";
NSString *VKDECODER_OPT_VALUE_RTSP_TRANSPORT_HTTP               = @"http";



//stream info data keys
NSString *STREAMINFO_KEY_CONNECTION                             = @"stream_info_connection";
NSString *STREAMINFO_KEY_DOWNLOAD                               = @"stream_info_download";
NSString *STREAMINFO_KEY_BITRATE                                = @"stream_info_bitrate";
NSString *STREAMINFO_KEY_AUDIO                                  = @"stream_info_audio";
NSString *STREAMINFO_KEY_VIDEO                                  = @"stream_info_video";

//C variables & functions
static int decode_interrupt_cb(void *decoder);
static int lockmgr(void **mtx, enum AVLockOp op);
extern const char *av_get_pix_fmt_name(enum AVPixelFormat pix_fmt);
extern double av_display_rotation_get(const int32_t matrix[9]);

#if !TARGET_OS_TV
enum AVPixelFormat vk_get_format(struct AVCodecContext *s, const enum AVPixelFormat * fmt);
#endif

#ifdef DEBUG
    VKLogLevel log_level = kVKLogLevelStateChanges;
#else
    VKLogLevel log_level = kVKLogLevelDisable;
#endif

//defines
#define FLAGS(o) ((o)->type == AV_OPT_TYPE_FLAGS) ? AV_DICT_APPEND : 0
#define INVALID_VALUE        -1

//Audio & Video default queue sizes
#define DEFAULT_VIDEO_PICTURE_QUEUE_SIZE            3
#define DEFAULT_MAX_QUEUE_SIZE                      15 * 1024 * 1024
#define DEFAULT_MIN_FRAMES_TO_START_PLAYING         15 /* get packets till this number, higher value increases buffering time */

//Decoder default log frequencies
#define DEFAULT_AV_SYNC_LOG_FREQUENCY               0.01
#define DEFAULT_VKLog_PKT_COUNT_SHOW_FREQUENCY      0.01
#define DEFAULT_AV_PKT_READ_ERR_LOG_FREQUENCY       0.01

#define CONFIG_RTSP_DEMUXER                         1
#define CONFIG_MMSH_PROTOCOL                        1

/* external clock speed adjustment constants for realtime sources based on buffer fullness */
#define EXTERNAL_CLOCK_SPEED_MIN                    0.900
#define EXTERNAL_CLOCK_SPEED_MAX                    1.010
#define EXTERNAL_CLOCK_SPEED_STEP                   0.001

#pragma mark -

@interface VKDecodeManager () {

    AVFormatContext* _avFmtCtx;/* ffmpeg format context */

    NSURL *_streamURL; /* stream url, supported protocols http, mms, rtsp, rtmp */
    NSDictionary *_decodeOptions;

    //dispatch queues
    dispatch_queue_t _readPktQueue;

    //AV Decoders
    VKVideoDecoder *_vDecoder;
    VKAudioDecoder *_aDecoder;

#ifdef VK_RECORDING_CAPABILITY
    //AV Recorder
    VKRecorder *_recorder;
#endif
    
    BOOL _audioIsOK;
    BOOL _videoIsOK;

    BOOL _readJobIsDone;
    BOOL _lastPaused;
    BOOL _initialBuffer;

    NSUInteger _frameWidth;
    NSUInteger _frameHeight;
    VKVideoStreamColorFormat _videoStreamColorFormat;

    VKDecoderState _decoderState;
    BOOL _appIsInBackgroundNow;
    int _readPktErrorCount;

    //Reachability
    VKReachability *_reachability;

    //Stream control values
    BOOL _streamIsPaused;
    int _abortIsRequested;
    int _readPauseCode;
    
    //Audio & Video Codecs parameters
    int _errorConcealment;
    int _workaroundBugs;
    int lowres;

    //Decoder limit parameters
    int64_t _probeSize;
    int64_t _maxAnalyzeDuration;
    BOOL _remoteFileStreaming;
    int _videoPictureQueueSize;
    int _maxQeueueSize;
    int _minFramesToStartPlaying;

    //Decoder logging parameters
    VKLogLevel _logLevel;
    float _avSyncLogFrequency;
    float _avPacketCountLogFrequency;
    float _avPacketReadErrorCountLogFrequency;
    
    int _pktCountIter;
    int _pktReadErrIter;

    int _avSyncType;

    int genpts;
    double _maxFrameDuration;      // maximum duration of a frame - above this, we consider the jump a timestamp discontinuity
    int _realTime;
    int _showStatus;
    int _fast;
    int _infiniteBuffer;
    int64_t _duration;

    int _seekRequest;
    int _seekFlags;
    int64_t _seekPosition;
    int64_t _seekRel;

    int _step;
    int _loopPlayback;
    BOOL _autoStopAtEnd;
    float _volumeLevel;
    float _panningLevel;

    dispatch_semaphore_t _semaReadThread;
    int _lastVideoStream, _lastAudioStream;
    int _queueAttachmentsReq;

    float _durationInSeconds;

    BOOL _audioIsDisabled;
    BOOL _videoIsDisabled;
    int _seekByBytes;
    
    VKClockManager *clockManager;
    
#ifdef VK_RECORDING_CAPABILITY
    BOOL _recordingNow;
#endif
    
    //for trial only
#ifdef TRIAL
    NSTimer *_timerTrial; /* sets stream duration to a limited time */
    BOOL _trialReadError;
#endif

}

@end


@implementation VKDecodeManager

#pragma mark - Public variables

@synthesize streamIsPaused = _streamIsPaused;
@synthesize abortIsRequested = _abortIsRequested;
@synthesize readPauseCode = _readPauseCode;

@synthesize frameWidth = _frameWidth;
@synthesize frameHeight = _frameHeight;
@synthesize videoStreamColorFormat = _videoStreamColorFormat;

@synthesize totalBytesDownloaded = _totalBytesDownloaded;
@synthesize streamInfo = _streamInfo;

@synthesize appIsInBackgroundNow = _appIsInBackgroundNow;

@synthesize videoPictureQueueSize = _videoPictureQueueSize;
@synthesize maxQueueSize = _maxQeueueSize;
@synthesize minFramesToStartPlaying = _minFramesToStartPlaying;
@synthesize avSyncLogFrequency = _avSyncLogFrequency;
@synthesize avPacketCountLogFrequency = _avPacketCountLogFrequency;
@synthesize avPacketReadErrorCountLogFrequency = _avPacketReadErrorCountLogFrequency;

@synthesize maxFrameDuration = _maxFrameDuration;
@synthesize step = _step;

@synthesize probeSize = _probeSize;
@synthesize maxAnalyzeDuration = _maxAnalyzeDuration;
@synthesize remoteFileStreaming = _remoteFileStreaming;
@synthesize durationInSeconds = _durationInSeconds;
@synthesize audioIsDisabled = _audioIsDisabled;
@synthesize initialPlaybackTime = _initialPlaybackTime;
@synthesize loopPlayback = _loopPlayback;
@synthesize autoStopAtEnd = _autoStopAtEnd;
@synthesize showPicOnInitialBuffering = _showPicOnInitialBuffering;
@synthesize volumeLevel = _volumeLevel;
@synthesize panningLevel = _panningLevel;
@synthesize ffmpegVersion = _ffmpegVersion;
@synthesize useFFmpegSWScaleRender = _useFFmpegSWScaleRender;
@synthesize disableInnerBuffer = _disableInnerBuffer;
@synthesize externalClock = _externalClock;
@synthesize clockManager = _clockManager;
@synthesize disableWaitingForFirstIntraFrame = _disableWaitingForFirstIntraFrame;
@synthesize readErrorGot = _readErrorGot;
@synthesize disableDropVideoPackets = _disableDropVideoPackets;
@synthesize initialAVSync = _initialAVSync;
@synthesize useHWAcceleratedAudioDecoders = _useHWAcceleratedAudioDecoders;
@synthesize useHWAcceleratedVideoDecoders = _useHWAcceleratedVideoDecoders;
@synthesize videoFramesAngle = _videoFramesAngle;

#pragma mark - Initialization

- (id)init {
    return nil;
}

- (id)initWithUsername:(NSString *)username secret:(NSString *)secret {
    self = [super initWithUsername:username secret:secret];
    if(self) {
        [self initEngine];
        [self initReachability];
        [self createDispatchQueues];
        [self initExternalClock];
        [self initValues];
        
        _streamInfo = [[NSMutableDictionary alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReachabilityChanged:) name:kVKReachabilityChangedNotification object:nil];

    }
    return self;
}

- (void)initEngine {
    [super initEngine];
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            av_lockmgr_register(lockmgr);
        });
    });

    _ffmpegVersion = [[NSString alloc] initWithUTF8String:FFMPEG_VERSION];
    VKLog(kVKLogLevelDecoder, @"Decoder is using ffmpeg version      : %@", _ffmpegVersion);
    
    _clockManager = [[VKClockManager alloc] init];
}

- (void)initReachability {
    if(_reachability == nil) {
        _reachability = [[VKReachability reachabilityForInternetConnection] retain];
        [_reachability startNotifier];
    }
}

- (void)createDispatchQueues {
    _readPktQueue = dispatch_queue_create("read_dispatch_queue", NULL);
}

- (void)initSemaphore {
    _semaReadThread = dispatch_semaphore_create(0);
}

- (void)initExternalClock {
    _externalClock = [[VKClock alloc] initWithType:kVKClockTypeExternal];
    [_clockManager initClock:_externalClock serial:[_externalClock serialPtr]];
}

- (void)initValues {
    
    _avFmtCtx = NULL;
    _decoderState = kVKDecoderStateNone;
    _appIsInBackgroundNow = NO;
    
    _audioIsOK = NO;
    _videoIsOK = NO;

    _abortIsRequested = NO;
    _readPauseCode = 0;
    _initialBuffer = NO;

    _readJobIsDone = YES;

    _frameWidth = 0;
    _frameHeight = 0;

    _readPktErrorCount = 0;
    _totalBytesDownloaded = 0;

    //init default values
    _remoteFileStreaming = NO;
    _videoPictureQueueSize = DEFAULT_VIDEO_PICTURE_QUEUE_SIZE;
    _maxQeueueSize = DEFAULT_MAX_QUEUE_SIZE;
    _minFramesToStartPlaying = DEFAULT_MIN_FRAMES_TO_START_PLAYING;
    _avSyncLogFrequency = DEFAULT_AV_SYNC_LOG_FREQUENCY;
    _avPacketCountLogFrequency = DEFAULT_VKLog_PKT_COUNT_SHOW_FREQUENCY;
    _avPacketReadErrorCountLogFrequency = DEFAULT_AV_PKT_READ_ERR_LOG_FREQUENCY;
    _pktCountIter = 0;
    _pktReadErrIter = 0;
    
    _frameDisplayCycle = 1;
    
    _volumeLevel = 1.0;
    _panningLevel = 0.0;

    genpts = 0;
    _seekByBytes = -1;
    _showStatus = 1;
    _fast = 0;
    _infiniteBuffer = -1;
    _seekRequest = 0;
    _duration = AV_NOPTS_VALUE;
    
    _probeSize = -1;
    _maxAnalyzeDuration = -1;

    _step = 0;
    _loopPlayback = 1;
    _autoStopAtEnd = NO;
    _audioIsDisabled = NO;
    _showPicOnInitialBuffering = NO;
    
    _errorConcealment = 3;
    _workaroundBugs = 1;
    lowres = 0;

    _avSyncType = AV_SYNC_AUDIO_MASTER;
    _lastVideoStream = -1, _lastAudioStream = -1;
    _durationInSeconds = -1.0;
    _initialPlaybackTime = AV_NOPTS_VALUE;
    
    _videoStreamColorFormat = VKVideoStreamColorFormatUnknown;
    _useFFmpegSWScaleRender = NO;
    
    _disableWaitingForFirstIntraFrame = NO;
    
    _readErrorGot = NO;
    
    _disableDropVideoPackets = NO;
    
    _initialAVSync = NO;
    
    _useHWAcceleratedAudioDecoders = YES;
    _useHWAcceleratedVideoDecoders = YES;
  
#ifdef VK_RECORDING_CAPABILITY
    _recordingNow = NO;
#endif
}

#pragma mark - Connection

- (VKError)connectWithStreamURLString:(NSString*)urlString options:(NSDictionary *)options {

    AVDictionary *option = NULL;
    VKError err;
    NSString *urlStringFinal = NULL;
    [self setDecoderState:kVKDecoderStateConnecting errorCode:kVKErrorNone];
    _realTime = ![self isFileStream:urlString];
    _decodeOptions = [options retain];
    
    if (_abortIsRequested) {
        return kVKErrorStreamsNotAvailable;
    }
    
    BOOL passThrough = [[options objectForKey:VKDECODER_OPT_KEY_PASS_THROUGH] boolValue];
    BOOL useCache = [[options objectForKey:VKDECODER_OPT_KEY_CACHE_STREAM_ENABLE] boolValue];
    
    if (passThrough) {
        err = [self parseOptionsFromURLString:urlString finalURLString:&urlStringFinal];
        if (err != kVKErrorNone) {
            [self setDecoderState:kVKDecoderStateConnectionFailed errorCode:err];
            return err;
        }
        //url address may include space(s), If no encoding is applied, then nsurl will be nil
        _streamURL = [[NSURL URLWithString:[urlStringFinal stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]] retain];
    } else {
        //url address may include space(s), If no encoding is applied, then nsurl will be nil
        NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        err = (_realTime) ? [self checkProtocolForValidness:url] : kVKErrorNone;
        if (err != kVKErrorNone) {
            [self setDecoderState:kVKDecoderStateConnectionFailed errorCode:err];
            return err;
        }
        _streamURL = [[self updateProtocolSchemeIfNeeded:url cache:useCache] retain];
        option = (_realTime) ? [self updateProtocolSettingsWithURL:url] : NULL;
        urlStringFinal = (_realTime) ? [_streamURL description] : urlString;
    }
    
    err = [self openStreamURLString:urlStringFinal option:option];
    if (err != kVKErrorNone)
        return err;

    err = [self checkStreamsForURLString:urlStringFinal];
    if (err != kVKErrorNone)
        return err;

    _durationInSeconds = _avFmtCtx->duration / 1000000LL;
    if (_durationInSeconds <= 0.0)
        [self setDecoderState:kVKDecoderStateGotStreamDuration errorCode:kVKErrorStreamDurationNotFound];
    else
        [self setDecoderState:kVKDecoderStateGotStreamDuration errorCode:kVKErrorNone];

    [self setDecoderState:kVKDecoderStateConnected errorCode:kVKErrorNone];
    
    err = [self openAVStreams];
    if (err != kVKErrorNone)
        return err;
    
    if (_showStatus) {
        VKLog(kVKLogLevelDecoder, @"Stream info exists:");
        av_dump_format(_avFmtCtx, 0, [urlString UTF8String], 0);
    }
    
    [self performSelector:@selector(onReachabilityChanged:) withObject:nil];

    return kVKErrorNone;
}

- (VKError)checkProtocolForValidness:(NSURL *)url {
    if(![[url scheme] isEqualToString:@"mms"]  &&
       ![[url scheme] isEqualToString:@"mmsh"] &&
       ![[url scheme] isEqualToString:@"mmst"] &&
       ![[url scheme] isEqualToString:@"http"] &&
       ![[url scheme] isEqualToString:@"https"] &&
       ![[url scheme] isEqualToString:@"rtsp"] &&
       ![[url scheme] isEqualToString:@"rtsps"] &&
       ![[url scheme] isEqualToString:@"rtp"] &&
       ![[url scheme] isEqualToString:@"udp"] &&
       ![[url scheme] isEqualToString:@"tcp"] &&
       ![[url scheme] isEqualToString:@"tls"] &&
       ![[url scheme] isEqualToString:@"rtmp"] &&
       ![[url scheme] isEqualToString:@"rtmpt"] &&
       ![[url scheme] isEqualToString:@"rtmpe"] &&
       ![[url scheme] isEqualToString:@"rtmps"] &&
       ![[url scheme] isEqualToString:@"rtmpte"] &&
       ![[url scheme] isEqualToString:@"rtmpts"] &&
       ![[url scheme] isEqualToString:@"cache"] &&
       ![[url scheme] isEqualToString:@"ftp"]) {
        [self setDecoderState:kVKDecoderStateConnectionFailed errorCode:kVKErrorUnsupportedProtocol];
        return kVKErrorUnsupportedProtocol;
    }
    return kVKErrorNone;
}

- (NSURL *)updateProtocolSchemeIfNeeded:(NSURL *)url cache:(BOOL)useCache {
    NSURL *newURL;
    if([[url scheme] isEqualToString:@"mms"]) {
        NSString *urlString = [url description];
        urlString = [urlString stringByReplacingOccurrencesOfString:@"mms://" withString:@"mmst://"];
        newURL = [NSURL URLWithString:urlString];
    }else if(([[url scheme] isEqualToString:@"http"] ||
              [[url scheme] isEqualToString:@"https"]) && useCache) {
        NSString *urlString = [url description];
        urlString = [NSString stringWithFormat:@"cache:%@", urlString];
        newURL = [NSURL URLWithString:urlString];
    } else {
        newURL = url;
    }
    _streamURL = [newURL retain];
    return newURL;
}

- (AVDictionary*)updateProtocolSettingsWithURL:(NSURL*) url {
    AVDictionary *option_dict = NULL;
    if ([[_streamURL scheme] isEqualToString:@"rtsp"]) {
        const struct AVOption *of = NULL;
        const AVClass *fc = avformat_get_class();

        //TCP is the default transport layer for RTSP protocol unless decoder options are given.
        const char *key = [VKDECODER_OPT_KEY_RTSP_TRANSPORT UTF8String];
        const char *val = [VKDECODER_OPT_VALUE_RTSP_TRANSPORT_TCP UTF8String];

        if (_decodeOptions && [_decodeOptions count]) {
            NSString *valStr = [_decodeOptions objectForKey:VKDECODER_OPT_KEY_RTSP_TRANSPORT];
            if (valStr &&
                ([valStr isEqualToString:VKDECODER_OPT_VALUE_RTSP_TRANSPORT_UDP] ||
                 [valStr isEqualToString:VKDECODER_OPT_VALUE_RTSP_TRANSPORT_UDP_MULTICAST] ||
                 [valStr isEqualToString:VKDECODER_OPT_VALUE_RTSP_TRANSPORT_HTTP])) {
                val = (char *)[valStr UTF8String];
            }
        }
        
        if ((of = av_opt_find(&fc, key, NULL, 0,
                              AV_OPT_SEARCH_CHILDREN | AV_OPT_SEARCH_FAKE_OBJ))){
            av_dict_set(&option_dict, key, val, FLAGS(of));
        }
    }
    return option_dict;
}

- (VKError)openStreamURLString:(NSString *)urlString option:(AVDictionary *)option {

    if (_abortIsRequested) {
        return kVKErrorStreamsNotAvailable;
    }

    _avFmtCtx = [self allocateContext];
    _avFmtCtx->interrupt_callback.callback = decode_interrupt_cb;
    _avFmtCtx->interrupt_callback.opaque = self;
    VKLog(kVKLogLevelDecoder, @"_avFmtCtx is allocated now");
    
    BOOL passThrough = [[_decodeOptions objectForKey:VKDECODER_OPT_KEY_PASS_THROUGH] boolValue];
    
    const char *input = [urlString UTF8String];
    
    int errConn = 0;
    if (passThrough) {
        if ((errConn = [self startConnectionWithContext:&_avFmtCtx fileName:input avInput:NULL options:&format_opts userOptions:&format_opts])) {
            [self setDecoderState:kVKDecoderStateConnectionFailed errorCode:kVKErrorOpenStream];
            char err_buf[2048];
            av_strerror(errConn, err_buf, sizeof(err_buf));
            NSString *errString = [NSString stringWithUTF8String:err_buf];
            VKLog(kVKLogLevelDecoder, @"Connection error code: %d details: %@", AVERROR(errConn), errString);
            return kVKErrorOpenStream;
        }
    } else {
        if (_probeSize != -1) {
            _avFmtCtx->probesize = _probeSize;
        }
        
        if (_maxAnalyzeDuration != -1) {
            _avFmtCtx->max_analyze_duration = _maxAnalyzeDuration;
        }
        
        if (_decodeOptions && [_decodeOptions objectForKey:VKDECODER_OPT_KEY_FORCE_MJPEG]) {
            _avFmtCtx->iformat = av_find_input_format("mjpeg");
            _avFmtCtx->probesize = (_probeSize != -1) ? _probeSize : 32;
            _avFmtCtx->max_analyze_duration = 0;
        }
        
        if ((errConn = [self startConnectionWithContext:&_avFmtCtx fileName:input avInput:NULL options:&option userOptions:NULL])) {
            [self setDecoderState:kVKDecoderStateConnectionFailed errorCode:kVKErrorOpenStream];
            char err_buf[2048];
            av_strerror(errConn, err_buf, sizeof(err_buf));
            NSString *errString = [NSString stringWithUTF8String:err_buf];
            VKLog(kVKLogLevelDecoder, @"Connection error code: %d details: %@", AVERROR(errConn), errString);
            return kVKErrorOpenStream;
        }
    }
    
    AVDictionaryEntry *t;
    if ((t = av_dict_get(format_opts, "", NULL, AV_DICT_IGNORE_SUFFIX))) {
        //av_log(NULL, AV_LOG_ERROR, "Option %s not found.\n", t->key);
        //ret = AVERROR_OPTION_NOT_FOUND;
        //goto fail;
        return kVKErrorOpenStream;
    }
    
    //Generate missing pts even if it requires parsing future frames
    if (genpts)
        _avFmtCtx->flags |= AVFMT_FLAG_GENPTS;
    
    return kVKErrorNone;
}

- (VKError)checkStreamsForURLString:(NSString *)urlString {

    if (_abortIsRequested) {
        return kVKErrorStreamsNotAvailable;
    }

    AVDictionary **opts;
    opts = setup_find_stream_info_opts(_avFmtCtx, codec_opts);
    int originalNumberStreams = _avFmtCtx->nb_streams;
    
    //Check the streams
    if(avformat_find_stream_info(_avFmtCtx, opts) < 0) {
        [self setDecoderState:kVKDecoderStateConnectionFailed errorCode:kVKErrorStreamInfoNotFound];
        return kVKErrorStreamInfoNotFound;
    }

    for (int i = 0; i < originalNumberStreams; i++){
        if (&opts[i]) {
            av_dict_free(&opts[i]);
        }
    }
    av_freep(&opts);

    if (_avFmtCtx->pb)
        _avFmtCtx->pb->eof_reached = 0; //fix from ffplay
    
    if (_seekByBytes < 0) {
        _seekByBytes = !!(_avFmtCtx->iformat->flags & AVFMT_TS_DISCONT) && strcmp("ogg", _avFmtCtx->iformat->name);
    }
    
    if (_disableInnerBuffer) {
        _avFmtCtx->flags |= AVFMT_FLAG_FLUSH_PACKETS;
        _infiniteBuffer = 0;
    }
    
    _maxFrameDuration = (_avFmtCtx->iformat->flags & AVFMT_TS_DISCONT) ? 10.0 : 3600.0;
    
    /* if seeking requested, we execute it */
    if (_initialPlaybackTime != AV_NOPTS_VALUE) {
        int64_t timestamp;
        
        timestamp = _initialPlaybackTime;
        /* add the stream start time */
        if (_avFmtCtx->start_time != AV_NOPTS_VALUE)
            timestamp += _avFmtCtx->start_time;
        int ret = avformat_seek_file(_avFmtCtx, -1, INT64_MIN, timestamp, INT64_MAX, 0);
        if (ret < 0) {
            VKLog(kVKLogLevelDecoder, @"Could not seek to position %0.3f", (double)timestamp / AV_TIME_BASE);
        }
    }
    return kVKErrorNone;
}

#pragma mark - Streams management

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (VKError)openAVStreams {

    if (_abortIsRequested) {
        return kVKErrorStreamsNotAvailable;
    }
    
    NSInteger aStreamId = INVALID_VALUE;
    NSInteger vStreamId = INVALID_VALUE;

    for (int i = 0; i < _avFmtCtx->nb_streams; i++)
        _avFmtCtx->streams[i]->discard = AVDISCARD_ALL;
    
    if (!_videoIsDisabled) {
        vStreamId = av_find_best_stream(_avFmtCtx, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
        if (vStreamId < 0) {
            vStreamId = INVALID_VALUE;
        } else {
            [self updateStreamInfoWithSelectedStreamIndex:(int)vStreamId type:AVMEDIA_TYPE_VIDEO];
        }
    }

    if (_avFmtCtx->bit_rate)
        [_streamInfo setValue: [NSNumber numberWithLongLong:_avFmtCtx->bit_rate]
                       forKey:STREAMINFO_KEY_BITRATE];

    NSNumber *aStreamOptIndex = [_decodeOptions objectForKey:VKDECODER_OPT_KEY_AUD_STRM_DEF_IDX];
    BOOL hasDefaultAudStreamIdx = NO;
    if (aStreamOptIndex) {
        hasDefaultAudStreamIdx = YES;
    }

    NSString *aStreamOptStr = [_decodeOptions objectForKey:VKDECODER_OPT_KEY_AUD_STRM_DEF_STR];
    BOOL hasDefaultAudioStreamStr = NO;
    if (aStreamOptStr) {
        hasDefaultAudioStreamStr = YES;
    }

    BOOL audioStreamIsSelected = NO;

    for (int sIdx = 0; sIdx < _avFmtCtx->nb_streams; sIdx++) {

        AVStream *stream = _avFmtCtx->streams[sIdx];
        AVCodecContext *codec = stream->codec;
        
        if (!_audioIsDisabled && (codec->codec_type == AVMEDIA_TYPE_AUDIO && codec->channels > 0) && !audioStreamIsSelected) {

            AVDictionaryEntry *langEntry = av_dict_get(stream->metadata, "language", NULL, 0);
            NSString *lang = @"default_language";
            if (langEntry && langEntry->value) {
                lang = [NSString stringWithFormat:@"%s", langEntry->value];
            }
        
            if (hasDefaultAudioStreamStr && !hasDefaultAudStreamIdx) {
                if ([lang isEqualToString:[_decodeOptions objectForKey:VKDECODER_OPT_KEY_AUD_STRM_DEF_STR]]) {
                    audioStreamIsSelected = YES;
                }
            }

            if (hasDefaultAudStreamIdx) {
                if (stream->id == [[_decodeOptions objectForKey:VKDECODER_OPT_KEY_AUD_STRM_DEF_IDX] intValue]) {
                    audioStreamIsSelected = YES;
                }
            }

            //If no default is given set selected audio stream index as the first audio stream
            if (!(hasDefaultAudioStreamStr || hasDefaultAudStreamIdx)) {
                audioStreamIsSelected = YES;
            }
            aStreamId = sIdx;
            [self updateStreamInfoWithSelectedStreamIndex:(int)aStreamId type:AVMEDIA_TYPE_AUDIO];
        }
    }

    /* Check audio codec and initialize audio decoder */
    VKError errAudio = kVKErrorNone;
    if (aStreamId != INVALID_VALUE) {
        errAudio = [self openAudioStreamWithId:aStreamId];
        if (errAudio == kVKErrorNone){
            _avFmtCtx->streams[aStreamId]->discard = AVDISCARD_DEFAULT;
            _audioIsOK = YES;
        }
    } else {
        errAudio = kVKErrorAudioStreamNotFound;
    }
    [self setDecoderState:kVKDecoderStateGotAudioStreamInfo errorCode:errAudio];

    /* Check video codec and initialize video decoder */
    VKError errVideo = kVKErrorNone;
    if (vStreamId != INVALID_VALUE) {
        errVideo = [self openVideoStreamWithId:vStreamId audioIsOK:_audioIsOK];
        if(errVideo == kVKErrorNone) {
            _avFmtCtx->streams[vStreamId]->discard = AVDISCARD_DEFAULT;
            _videoIsOK = YES;
        }
    } else {
        errVideo = kVKErrorVideoStreamNotFound;
    }
    [self setDecoderState:kVKDecoderStateGotVideoStreamInfo errorCode:errVideo];

    if ((errAudio != kVKErrorNone) && (errVideo != kVKErrorNone))
        return kVKErrorStreamsNotAvailable;

    return kVKErrorNone;
}

- (VKError)openAudioStreamWithId:(NSInteger)sId {

    if (_audioIsOK) {
        return kVKErrorAudioStreamAlreadyOpened;
    }

    AVDictionary *opts;
    AVDictionaryEntry *t = NULL;
    AVCodecContext *audCdcCtx = _avFmtCtx->streams[sId]->codec;

    AVCodec *audCdc = avcodec_find_decoder(audCdcCtx->codec_id);
    
    if(!audCdc) {
        return kVKErrorAudioCodecNotFound;
    }
    
    char codecAudioToolbox[32];
    sprintf(codecAudioToolbox, "%s_at",audCdc->name);
    if (_useHWAcceleratedAudioDecoders && avcodec_find_decoder_by_name(codecAudioToolbox)) {
        audCdc = avcodec_find_decoder_by_name(codecAudioToolbox);
    } else {
        audCdc = avcodec_find_decoder(audCdcCtx->codec_id);
    }

    int stream_lowres = lowres;

    audCdcCtx->workaround_bugs   = _workaroundBugs;

    if(stream_lowres > av_codec_get_max_lowres(audCdc)) {
        VKLog(kVKLogLevelDecoder, @"The maximum value for lowres supported by the decoder is %d",
               av_codec_get_max_lowres(audCdc));
        stream_lowres = av_codec_get_max_lowres(audCdc);
    }
    
    av_codec_set_lowres(audCdcCtx, stream_lowres);
    audCdcCtx->error_concealment = _errorConcealment;
    
    if(stream_lowres)
        audCdcCtx->flags |= CODEC_FLAG_EMU_EDGE;
    
    if (_fast)
        audCdcCtx->flags2 |= CODEC_FLAG2_FAST;
    
    if(audCdc->capabilities & CODEC_CAP_DR1)
        audCdcCtx->flags |= CODEC_FLAG_EMU_EDGE;

    opts = filter_codec_opts(codec_opts, audCdcCtx->codec_id, _avFmtCtx, _avFmtCtx->streams[sId], audCdc);
    if (!av_dict_get(opts, "threads", NULL, 0))
        av_dict_set(&opts, "threads", "auto", 0);
    
    if (stream_lowres) {
        char temp[32];
        sprintf(temp, "%d", stream_lowres);
        av_dict_set(&opts, "lowres", temp, AV_DICT_DONT_STRDUP_VAL);
    }
    
    if (audCdcCtx->codec_type == AVMEDIA_TYPE_AUDIO)
        av_dict_set(&opts, "refcounted_frames", "1", 0);

    if(avcodec_open2(audCdcCtx, audCdc, &opts)){
        return kVKErrorAudioCodecNotOpened;
    }

    if ((t = av_dict_get(opts, "", NULL, AV_DICT_IGNORE_SUFFIX))) {
        VKLog(kVKLogLevelDecoder, @" Option %s not found.", t->key);
        return kVKErrorAudioCodecOptNotFound;
    }

    _aDecoder = [[VKAudioDecoder alloc] initWithFormatContext:_avFmtCtx codecContext:audCdcCtx stream:_avFmtCtx->streams[sId] streamId:sId manager:self];
    
    if (!_aDecoder) {
        return kVKErrorAudioAllocateMemory;
    }
    VKLog(kVKLogLevelDecoder, @"audio codec smr: %.d fmt: %d chn: %d",
         audCdcCtx->sample_rate, audCdcCtx->sample_fmt, audCdcCtx->channels);

    _lastAudioStream = (int)sId;
    
    return kVKErrorNone;
}

- (VKError)openVideoStreamWithId:(NSInteger)sId audioIsOK:(BOOL)audioIsOK {

    AVDictionary *opts;
    AVDictionaryEntry *t = NULL;

    AVCodecContext *vidCdcCtx = _avFmtCtx->streams[sId]->codec;
    
#if !TARGET_OS_TV && !TARGET_IPHONE_SIMULATOR
    if (_useHWAcceleratedVideoDecoders && vidCdcCtx->codec_id == AV_CODEC_ID_H264) {
        vidCdcCtx->get_format = vk_get_format;
        vidCdcCtx->pix_fmt = AV_PIX_FMT_VIDEOTOOLBOX;
    }
#endif
    
    AVCodec *vidCdc = avcodec_find_decoder(vidCdcCtx->codec_id);
    int stream_lowres = lowres;

    if(!vidCdc) {
        VKLog(kVKLogLevelDecoder, @"Video codec is not found");
        return kVKErrorVideoCodecNotFound;
    }

    vidCdcCtx->workaround_bugs   = _workaroundBugs;
    
    if(stream_lowres > av_codec_get_max_lowres(vidCdc)) {
        VKLog(kVKLogLevelDecoder, @"The maximum value for lowres supported by the decoder is %d",
              av_codec_get_max_lowres(vidCdc));
        stream_lowres = av_codec_get_max_lowres(vidCdc);
    }
    
    av_codec_set_lowres(vidCdcCtx, stream_lowres);
    vidCdcCtx->error_concealment = _errorConcealment;
    
    vidCdcCtx->lowres            = lowres;
    if(vidCdcCtx->lowres > vidCdc->max_lowres){
        vidCdcCtx->lowres= vidCdc->max_lowres;
    }
    
    vidCdcCtx->error_concealment = _errorConcealment;

    if(vidCdcCtx->lowres)
        vidCdcCtx->flags |= CODEC_FLAG_EMU_EDGE;
    
    if (_fast)
        vidCdcCtx->flags2 |= CODEC_FLAG2_FAST;

    if(vidCdc->capabilities & CODEC_CAP_DR1)
        vidCdcCtx->flags |= CODEC_FLAG_EMU_EDGE;
    
    if (_disableWaitingForFirstIntraFrame) {
        vidCdcCtx->flags2 |= CODEC_FLAG2_SHOW_ALL;
    }

    opts = filter_codec_opts(codec_opts, vidCdcCtx->codec_id, _avFmtCtx, _avFmtCtx->streams[sId], vidCdc);
    
    if (stream_lowres) {
        char temp[32];
        sprintf(temp, "%d", stream_lowres);
        av_dict_set(&opts, "lowres", temp, AV_DICT_DONT_STRDUP_VAL);
    }
    
    if (vidCdcCtx->codec_type == AVMEDIA_TYPE_VIDEO)
        av_dict_set(&opts, "refcounted_frames", "1", 0);

    if(avcodec_open2(vidCdcCtx, vidCdc, &opts)){
        VKLog(kVKLogLevelDecoder, @" Video codec is not opened");
        return kVKErrorVideoCodecNotOpened;
    }

    if ((t = av_dict_get(opts, "", NULL, AV_DICT_IGNORE_SUFFIX))) {
        VKLog(kVKLogLevelDecoder, @" Option %s not found.", t->key);
        return kVKErrorVideoCodecOptNotFound;
    }

    _frameWidth = vidCdcCtx->width;
    _frameHeight = vidCdcCtx->height;
    
    for (int i = 0; i < _avFmtCtx->streams[sId]->nb_side_data; i++) {
        AVPacketSideData sd = _avFmtCtx->streams[sId]->side_data[i];
        
        switch (sd.type) {
            case AV_PKT_DATA_DISPLAYMATRIX:
                _videoFramesAngle = av_display_rotation_get((int32_t *)sd.data);
                VKLog(kVKLogLevelDecoder, @" Video stream has display matrix with angle %.2f degrees", _videoFramesAngle);
                break;
            default:
                break;
        }
        
    }
    
    if(_useFFmpegSWScaleRender) {
        _videoStreamColorFormat = VKVideoStreamColorFormatRGB;
    } else {
        const char *formatCStr = (const char *)av_get_pix_fmt_name(vidCdcCtx->pix_fmt);
        NSString *formatStr = (formatCStr) ? [NSString stringWithUTF8String:formatCStr] : @"";
        if (formatStr && [formatStr length]) {
            if ([formatStr rangeOfString:@"videotoolbox"].location != NSNotFound) {
                _videoStreamColorFormat = VKVideoStreamColorFormatYUVVT;
            } else if ([formatStr rangeOfString:@"yuv"].location != NSNotFound) {
                _videoStreamColorFormat = VKVideoStreamColorFormatYUV;
            } else {
                _videoStreamColorFormat = VKVideoStreamColorFormatRGB;
            }
        }
    }
    
    if (!av_dict_get(opts, "threads", NULL, 0)) {
        if (_videoStreamColorFormat != VKVideoStreamColorFormatYUVVT) {
            av_dict_set(&opts, "threads", "auto", 0);
        }
    }
    
    _queueAttachmentsReq = 1;

    _vDecoder = [[VKVideoDecoder alloc] initWithFormatContext:_avFmtCtx codecContext:vidCdcCtx stream:_avFmtCtx->streams[sId] streamId:sId manager:self audioDecoder:_aDecoder];
    
    if (!_vDecoder) {
        VKLog(kVKLogLevelDecoder, @"Video decoder can not be allocated");
        return kVKErrorVideoAllocateMemory;
    }

    _lastVideoStream = (int)sId;
    
    return kVKErrorNone;
}

- (void)closeAudioStream {
    if (_audioIsOK) {
        _audioIsOK = NO;
        [_aDecoder shutdown];
        [_aDecoder release];
        _aDecoder = NULL;
    }
}

- (void)closeVideoStream {
    if (_videoIsOK) {
        _videoIsOK = NO;
        [_vDecoder shutdown];
        [_vDecoder release];
        _vDecoder = NULL;
    }
}

#ifdef VK_RECORDING_CAPABILITY
#pragma mark - Recording actions

- (void)startRecording {
    if (_recordingNow || _recorder) {
        return;
    }
    
    int audioStreamId = INVALID_VALUE;
    int videoStreamId = INVALID_VALUE;
    
    if (_audioIsOK) {
        audioStreamId = (int)[_aDecoder streamId];
    }
    
    if (_videoIsOK) {
        videoStreamId = (int)[_vDecoder streamId];
    }

    _recorder = [[VKRecorder alloc] initWithInputFormat:_avFmtCtx activeAudioStreamId:audioStreamId
                                    activeVideoStreamId:videoStreamId fullPathWithFileName:NULL];
    if (!_recorder)
        return;
    _recorder.delegate = self;
    [_recorder start];
}

- (void)stopRecording {
    [_recorder stop];
}
#endif

#pragma mark & delegation

#ifdef VK_RECORDING_CAPABILITY
- (void)didStartRecordingWithRecorder:(VKRecorder *)recorder {
    _recordingNow = YES;
    //notify the player
    VKLog(kVKLogLevelDecoder, @"*** Recording is started now ...");
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if(_delegate && [_delegate respondsToSelector:@selector(didStartRecordingWithPath:)]) {
            [_delegate didStartRecordingWithPath:[recorder recordPath]];
        }
    });
}

- (void)didStopRecordingWithRecorder:(VKRecorder *)recorder error:(VKErrorRecorder)error {
    if (error == kVKErrorRecorderNone) {
        VKLog(kVKLogLevelDecoder, @"** Recording is done with success **");
    } else {
        VKLog(kVKLogLevelDecoder, @"-- Recording is FAILED with error = %d", (int)error);
    }
    
    _recordingNow = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if(_delegate && [_delegate respondsToSelector:@selector(didStopRecordingWithPath:error:)]) {
            [_delegate didStopRecordingWithPath:[[[recorder recordPath] copy] autorelease] error:error];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_recorder setDelegate:nil];
            [_recorder release];
            _recorder = NULL;
            VKLog(kVKLogLevelDecoder, @"** Recorder is completely removed **");
        });
    });
}
#endif

#pragma mark - Read & control packets

- (void)startToReadAndDecode {
    if (!_abortIsRequested) {
        VKLog(kVKLogLevelDecoder, @"VKDecodeManager is now starting to read packets");
        [self initSemaphore];
        [self setDecoderState:kVKDecoderStateInitialLoading errorCode:kVKErrorNone];
        [self readPackets];
    }
}

- (void) readPackets {

    dispatch_async(_readPktQueue, ^(void) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        BOOL packetIsValid = NO;
        _readJobIsDone = NO;
        AVPacket packet;
        int err = 0;
        int pktInPlayRange = 0;
        int eof = 0;
        
        int audPktCount = 0;
        int vidPktCount = 0;
        int aQueueSize = 0;
        int vQueueSize = 0;
        
        if (_infiniteBuffer < 0 && [self isRealTime]) {
            _infiniteBuffer = 1;
        }

        for (;;) {
            NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
            
            if (_abortIsRequested){
                [subPool release];
                break;
            }
            if (_streamIsPaused != _lastPaused) {
                _lastPaused = _streamIsPaused;
                if (_streamIsPaused)
                    _readPauseCode = av_read_pause(_avFmtCtx);
                else
                    av_read_play(_avFmtCtx);
            }

#if CONFIG_RTSP_DEMUXER || CONFIG_MMSH_PROTOCOL
            if (_realTime && _streamIsPaused &&
                (!strcmp(_avFmtCtx->iformat->name, "rtsp") ||
                 (_avFmtCtx->pb && !strncmp([[_streamURL description] UTF8String], "mmsh:", 5)))) {
                    /* wait 10 ms to avoid trying to get another packet for above protocols */
                    [NSThread sleepForTimeInterval:0.01];
                    continue;
                }
#endif

            if (_seekRequest) {
                int64_t seek_target = _seekPosition;
                int64_t seek_min    = _seekRel > 0 ? seek_target - _seekRel + 2: INT64_MIN;
                int64_t seek_max    = _seekRel < 0 ? seek_target - _seekRel - 2: INT64_MAX;
                // FIXME the +-2 is due to rounding being not done in the correct direction in generation
                //      of the _seekPosition/_seekRel variables
                
                if (_disableWaitingForFirstIntraFrame) {
                    if(seek_target == 0.0) {
                        _seekFlags |= AVSEEK_FLAG_ANY;
                    } else {
                        _seekFlags &= ~AVSEEK_FLAG_ANY;
                    }
                }

                int ret = avformat_seek_file(_avFmtCtx, -1, seek_min, seek_target, seek_max, _seekFlags);
                if (ret < 0) {
                    fprintf(stderr, "%s: error while seeking\n", _avFmtCtx->filename);
                } else {
                    if (_audioIsOK) {
                        pthread_mutex_lock([_aDecoder mutexPkt]);
                        [_aDecoder clearPktQueue];
                        [_aDecoder addFlushPkt];
                        pthread_mutex_unlock([_aDecoder mutexPkt]);
                    }
                    if (_videoIsOK) {
                        pthread_mutex_lock([_vDecoder mutexPkt]);
                        [_vDecoder clearPktQueue];
                        [_vDecoder addFlushPkt];
                        pthread_mutex_unlock([_vDecoder mutexPkt]);
                    }
  
#ifdef VK_RECORDING_CAPABILITY
                    if (_recordingNow) {
                        pthread_mutex_lock([_recorder mutexPkt]);
                        [_recorder clearPktQueue];
                        [_recorder addFlushPkt];
                        pthread_mutex_unlock([_recorder mutexPkt]);
                    }
#endif
                    if (_seekFlags & AVSEEK_FLAG_BYTE) {
                        [_clockManager setClockTime:_externalClock pts:NAN serial:0];
                    } else {
                        [_clockManager setClockTime:_externalClock pts:(seek_target/(double)AV_TIME_BASE) serial:0];
                    }
                }

                _seekRequest = 0;
                _queueAttachmentsReq = 1;
                eof = 0;

                if (_streamIsPaused)
                    [self stepToNextFrame];

                if (_queueAttachmentsReq) {
                    
                    if (_videoIsOK  && _avFmtCtx->streams[[_vDecoder streamId]]->disposition & AV_DISPOSITION_ATTACHED_PIC) {
                        AVPacket copy;
                        av_init_packet(&copy);
                        if ((ret = av_copy_packet(&copy, &_avFmtCtx->streams[[_vDecoder streamId]]->attached_pic)) < 0)
                            break;
                        
                        pthread_mutex_lock([_vDecoder mutexPkt]);
                        [_vDecoder addPacket:&copy];
                        pthread_cond_signal([_vDecoder condPkt]);
                        pthread_mutex_unlock([_vDecoder mutexPkt]);
                        
                        pthread_mutex_lock([_vDecoder mutexPkt]);
                        [_vDecoder addEmptyPkt];
                        pthread_cond_signal([_vDecoder condPkt]);
                        pthread_mutex_unlock([_vDecoder mutexPkt]);
                    }
                    _queueAttachmentsReq = 0;
                }
            }

            int modPktCount = 1/_avPacketCountLogFrequency;
            signed int totalSize = 0.0;
            
            audPktCount = 0;
            vidPktCount = 0;
            aQueueSize = 0;
            vQueueSize = 0;
            
            if (_audioIsOK) {
                audPktCount = (int)[[_aDecoder pktQueue] count];
                aQueueSize = (int)[_aDecoder pktQueueSize];
            }
            if (_videoIsOK) {
                vidPktCount = (int)[[_vDecoder pktQueue] count];
                vQueueSize = (int)[_vDecoder pktQueueSize];
            }
            totalSize = aQueueSize + vQueueSize;

            if((log_level & kVKLogLevelDecoderExtra) && (_pktCountIter%modPktCount == 0)){
                _pktCountIter = 0;

                printf("[vq=%d (%0.2f KB)  -   aq=%d (%0.2f KB)] - totalsize= %0.2f MB\n",
                       vidPktCount, (float)(vQueueSize)/1000.0,
                       audPktCount, (float)(aQueueSize)/1000.0,
                       (float)totalSize/1000000.0/*1024*1024*/);
            }
            _pktCountIter++;
            
            if (_infiniteBuffer < 1 && ((totalSize > _maxQeueueSize) ||
                                        (((!_audioIsOK) || [[_aDecoder pktQueue] count] > _minFramesToStartPlaying) &&
                                         ((!_videoIsOK) || [[_vDecoder pktQueue] count] > _minFramesToStartPlaying || (_avFmtCtx->streams[[_aDecoder streamId]]->disposition & AV_DISPOSITION_ATTACHED_PIC))))) {
                [NSThread sleepForTimeInterval:0.01];
                [subPool release];
                continue;
            } else if (_infiniteBuffer >= 1 && (totalSize > _maxQeueueSize/2)) {
                [NSThread sleepForTimeInterval:0.01];
                [subPool release];
                continue;
            }

            if (eof) {
                if (_videoIsOK) {
                    [_vDecoder addEmptyPkt];
                }

                if (_audioIsOK) {
                    AVStream *stream = _avFmtCtx->streams[[_aDecoder streamId]];
                    if (stream->codec->codec->capabilities & CODEC_CAP_DELAY) {
                        [_aDecoder addEmptyPkt];
                    }
                }

                [NSThread sleepForTimeInterval:0.01];

                if (totalSize == 0) {
                    if (_loopPlayback != 1 && (!_loopPlayback || --_loopPlayback)) {
                        [self streamSeek:(_initialPlaybackTime != AV_NOPTS_VALUE ? _initialPlaybackTime : 0) rel:0 byBytes:0];
                    } else if (_autoStopAtEnd) {
                        err = AVERROR_EOF;
                        VKLog(kVKLogLevelDecoder, @"End of file, nothing to be read err = %d !!!", err);
                        [self setDecoderState:kVKDecoderStateStoppedWithError errorCode:kVKErrorStreamEOFError];
                        [subPool release];
                        break;
                    }
                }
                
                eof = 0;
                [subPool release];
                continue;
            }

            err = av_read_frame(_avFmtCtx, &packet);
            
            BOOL playingTimeExpired = NO;

#ifdef TRIAL
            if(_trialReadError){
                playingTimeExpired = YES;
            }
#endif
            
            if (err < 0 || playingTimeExpired) {
                if (packet.data) {
                    av_free_packet(&packet);
                }
                
                if (err < 0 || playingTimeExpired) {
                    if (err == AVERROR_EOF || /*url_feof(_avFmtCtx->pb) // old API*/avio_feof(_avFmtCtx->pb)) {
                        
                        int modPktReadErrCount = 1/_avPacketReadErrorCountLogFrequency;
                        
                        if ((_pktReadErrIter%modPktReadErrCount == 0)) {
                            _pktReadErrIter = 0;
                            VKLog(kVKLogLevelDecoderExtra, @"End of file message received");
                        }
                        _pktReadErrIter++;

                        eof = 1;
                        if (_videoIsOK) [_vDecoder setEOF:eof];
                        if (_audioIsOK) [_aDecoder setEOF:eof];
                    }
                    if ((_avFmtCtx->pb && _avFmtCtx->pb->error) || playingTimeExpired) {
                        _readErrorGot = YES;
                        VKLog(kVKLogLevelDecoder, @"Read ERROR !!!");
                        [self setDecoderState:kVKDecoderStateStoppedWithError errorCode:kVKErrorStreamReadError];
                        [subPool release];
                        break;
                    }

                    [NSThread sleepForTimeInterval:0.01];
                    [subPool release];
                    continue;
                }
            }
            if (_videoIsOK) [_vDecoder setEOF:eof];
            if (_audioIsOK) [_aDecoder setEOF:eof];

            int64_t streamStartTime = _avFmtCtx->streams[packet.stream_index]->start_time;
            int64_t val1 = (packet.pts - (streamStartTime != AV_NOPTS_VALUE ? streamStartTime : 0)) * av_q2d(_avFmtCtx->streams[packet.stream_index]->time_base);
            double val2 = (double)(_initialPlaybackTime != AV_NOPTS_VALUE ? _initialPlaybackTime : 0) / 1000000;
            pktInPlayRange = _duration == AV_NOPTS_VALUE || val1 - val2 <= ((double)_duration / 1000000);
            
            packetIsValid = NO;
            
            if (_audioIsOK && (packet.stream_index == [_aDecoder streamId]) && pktInPlayRange) {
                
                pthread_mutex_lock([_aDecoder mutexPkt]);
                [_aDecoder addPacket:(AVPacket *)&packet];
                
                packetIsValid = YES;
                pthread_mutex_unlock([_aDecoder mutexPkt]);
                
            } else if ((_videoIsOK) && (packet.stream_index == [_vDecoder streamId]) && pktInPlayRange) {

                pthread_mutex_lock([_vDecoder mutexPkt]);
                [_vDecoder addPacket:(AVPacket *)&packet];

                pthread_cond_signal([_vDecoder condPkt]);
                pthread_mutex_unlock([_vDecoder mutexPkt]);

                packetIsValid = YES;
            }
            
            if (!_initialBuffer) {
                
                BOOL buffersReadyToPlay = (_initialAVSync) ? ((!_audioIsOK || [[_aDecoder pktQueue] count] > (_minFramesToStartPlaying)) &&
                                                              (!_videoIsOK || [[_vDecoder pktQueue] count] > (_minFramesToStartPlaying))) :
                ((_audioIsOK && [[_aDecoder pktQueue] count] > (_minFramesToStartPlaying)) ||
                 (_videoIsOK && [[_vDecoder pktQueue] count] > (_minFramesToStartPlaying)));
                
                if (buffersReadyToPlay) {
                    if (!_abortIsRequested) {
                        
                        if (_initialAVSync && _audioIsOK && _videoIsOK) {
                            double firstVideoPktValidTimeStamp = 0;
                            
                            for (int iterVidPTS = (int)([[_vDecoder pktQueue] count] -1); iterVidPTS >= 0; iterVidPTS--) {
                                VKPacket *pkt = [[_vDecoder pktQueue] objectAtIndex:iterVidPTS];
                                if (pkt.pts != AV_NOPTS_VALUE) {
                                    firstVideoPktValidTimeStamp = ((int64_t)pkt.pts) * av_q2d(_avFmtCtx->streams[[_vDecoder streamId]]->time_base);
                                    break;
                                }
                            }
                            
                            for (int iterAudioPkt = (int)([[_aDecoder pktQueue] count] -1); iterAudioPkt >= 0; iterAudioPkt--) {
                                VKPacket *pkt = [[_aDecoder pktQueue] objectAtIndex:iterAudioPkt];
                                
                                BOOL closedAudPktFound = (pkt.pts == AV_NOPTS_VALUE) ? NO : YES;
                                double diff = 0.0;
                                if(closedAudPktFound) {
                                    diff = firstVideoPktValidTimeStamp - (((int64_t)pkt.pts) * av_q2d(_avFmtCtx->streams[[_aDecoder streamId]]->time_base));
                                    if(diff > 0.2) {
                                        closedAudPktFound = NO;
                                    }
                                }
                                
                                if (!closedAudPktFound) {
                                    VKLog(kVKLogLevelDecoderExtra, @"AVDIFF: %f - AudioPkt is removed >>>>>", diff);
                                    [[_aDecoder pktQueue] removeObjectAtIndex:iterAudioPkt];
                                } else {
                                    VKLog(kVKLogLevelDecoderExtra, @"AVDIFF: %f - CLOSEST AUDIO PKT FOUND (Audpkts: %lu  / VidPkts: %lu)!!!", diff, (unsigned long)[[_aDecoder pktQueue] count], (unsigned long)[[_vDecoder pktQueue] count]);
                                    break;
                                }
                            }
                        }
                        
                        if (!_initialAVSync || (!_audioIsOK || [[_aDecoder pktQueue] count] > (_minFramesToStartPlaying))) {
                            _initialBuffer = YES;
                            [self setDecoderState:kVKDecoderStateReadyToPlay errorCode:kVKErrorNone];
                            [_aDecoder startAudioSystem];
                            [_vDecoder decodeVideo];
                            [_vDecoder performSelectorOnMainThread:@selector(schedulePicture) withObject:nil waitUntilDone:NO];
                            [self setDecoderState:kVKDecoderStatePlaying errorCode:kVKErrorNone];
                        }
                    }
                }
            }
            
            if (packet.data) {
                _totalBytesDownloaded += packet.size;

#ifdef VK_RECORDING_CAPABILITY
                if (packetIsValid && _recordingNow) {
                    pthread_mutex_lock([_recorder mutexPkt]);
                    [_recorder addPacket:(AVPacket *)&packet];
                    pthread_cond_signal([_recorder condPkt]);
                    pthread_mutex_unlock([_recorder mutexPkt]);
                }
#endif
                av_free_packet(&packet);
            }
            [subPool release];
        }

        /* wait until the end */
        while (!_abortIsRequested) {
            NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
            [NSThread sleepForTimeInterval:0.1];
            [p release];
        }

        [self shutDown];

        VKLog(kVKLogLevelDecoder, @"readPackets is ENDED!");
        _readJobIsDone = YES;

        dispatch_semaphore_signal(_semaReadThread);
        [pool release];
    });

}

#pragma mark - Decoder logging

- (void)setLogLevel:(VKLogLevel)logLevel {
    _logLevel = logLevel;
    log_level = _logLevel;
    
    if (log_level == kVKLogLevelDisable) {
        opt_loglevel(NULL, "loglevel", "quiet");
    }
}

#pragma mark - AV syncing

- (int)masterSyncType {
    if (_avSyncType == AV_SYNC_VIDEO_MASTER) {
        if (_videoIsOK)
            return AV_SYNC_VIDEO_MASTER;
        else
            return AV_SYNC_AUDIO_MASTER;
    } else if (_avSyncType == AV_SYNC_AUDIO_MASTER) {
        if (_audioIsOK)
            return AV_SYNC_AUDIO_MASTER;
        else
            return AV_SYNC_EXTERNAL_CLOCK;
    }
    return AV_SYNC_EXTERNAL_CLOCK;
}

/* get the current master clock value */
- (double)masterClock
{
    double val = 0.0;

    switch ([self masterSyncType]) {
        case AV_SYNC_VIDEO_MASTER:
            val = [_clockManager clockTime:[_vDecoder decoderClock]];
            break;
        case AV_SYNC_AUDIO_MASTER:
            val = [_clockManager clockTime:[_aDecoder decoderClock]];
            break;
        default:
            val = [_clockManager clockTime:_externalClock];
            break;
    }
    return val;
}

- (double)currentTime {
    if (_seekRequest) {
        return NAN;
    }
    return [self masterClock] - ((_avFmtCtx->start_time != AV_NOPTS_VALUE) ? _avFmtCtx->start_time/AV_TIME_BASE : 0);
}

- (void)checkExternalClockSpeed {
    if ((_videoIsOK && ([[_vDecoder pktQueue] count] <= _minFramesToStartPlaying / 2)) ||
        (_audioIsOK &&  ([[_aDecoder pktQueue] count] <= _minFramesToStartPlaying / 2))) {
        //[self updateExternalClockSpeed:FFMAX(EXTERNAL_CLOCK_SPEED_MIN, _externalClockSpeed - EXTERNAL_CLOCK_SPEED_STEP)];
        [_clockManager setSpeed:FFMAX(EXTERNAL_CLOCK_SPEED_MIN, _externalClock.speed + EXTERNAL_CLOCK_SPEED_STEP) clock:_externalClock];
        
    } else if ((!_videoIsOK || [[_vDecoder pktQueue] count] > _minFramesToStartPlaying * 2) &&
               (!_audioIsOK || [[_aDecoder pktQueue] count] > _minFramesToStartPlaying * 2)) {
        //[self updateExternalClockSpeed:FFMIN(EXTERNAL_CLOCK_SPEED_MAX, _externalClockSpeed + EXTERNAL_CLOCK_SPEED_STEP)];
        [_clockManager setSpeed:FFMIN(EXTERNAL_CLOCK_SPEED_MAX, _externalClock.speed + EXTERNAL_CLOCK_SPEED_STEP) clock:_externalClock];
        
    } else {
        double speed = _externalClock.speed;
        if (speed != 1.0) {
            //[self updateExternalClockSpeed:(speed + EXTERNAL_CLOCK_SPEED_STEP * (1.0 - speed) / fabs(1.0 - speed))];
            [_clockManager setSpeed:(speed + EXTERNAL_CLOCK_SPEED_STEP * (1.0 - speed) / fabs(1.0 - speed)) clock:_externalClock];
        }
    }
}

#pragma mark - Public Actions

- (void)sendRTSPCloseMessage {
#if CONFIG_RTSP_DEMUXER || CONFIG_MMSH_PROTOCOL
    if(_avFmtCtx && _avFmtCtx->iformat && !strcmp(_avFmtCtx->iformat->name, "rtsp")) {
        RTSPState *r = (RTSPState *)_avFmtCtx->priv_data;
        ff_rtsp_send_cmd_async(_avFmtCtx, "TEARDOWN", r->control_uri, NULL);
    }
#endif
}

- (void)togglePause
{
    [self streamTogglePause];
    _step = 0;
}

- (void)stepToNextFrame
{
    /* if the stream is paused unpause it, then step */
    if (_streamIsPaused)
        [self streamTogglePause];
    _step = 1;
}

- (void)abort {
    [super abort];
#ifdef TRIAL
    [self stopTrialTimer];
#endif
    
    if (_audioIsOK && _aDecoder) {
        [_aDecoder setAbortRequest:1];
    }
    if (_videoIsOK && _vDecoder) {
        [_vDecoder setAbortRequest:1];
    }
    _abortIsRequested = YES;
}

- (void)stop {
    [self abort];
#ifdef VK_RECORDING_CAPABILITY
    if (_recordingNow) {
        [self stopRecording];
    }
#endif
    
    if (_semaReadThread) {
        dispatch_semaphore_wait(_semaReadThread, DISPATCH_TIME_FOREVER);
        dispatch_release(_semaReadThread);
        _semaReadThread = NULL;
    } else {
        [self shutDown];
    }
    [self setDecoderState:kVKDecoderStateStoppedByUser errorCode:kVKErrorNone];

    VKLog(kVKLogLevelDecoder, @"-==@  DecodeManager is stopped safely  @==-  !!!");
}

- (void)doSeek:(double)value {

    double pos = 0.0;
    value += ((_avFmtCtx->start_time != AV_NOPTS_VALUE) ? _avFmtCtx->start_time/AV_TIME_BASE : 0);
    
    if (_seekByBytes) {
        if (_videoIsOK && [_vDecoder currentPos] >= 0) {
            pos = [_vDecoder currentPos];
        } else if (_audioIsOK && [_aDecoder currentPos] >= 0) {
            pos = [_aDecoder currentPos];
        } else
            pos = avio_tell(_avFmtCtx->pb);
        if (_avFmtCtx->bit_rate)
            value *= _avFmtCtx->bit_rate / 8.0;
        else
            value *= 180000.0;
        pos += value;
        [self streamSeek:pos rel:value byBytes:1];
    } else {
        pos = [self masterClock];
        if (isnan(pos))
            pos = (double)_seekPosition / AV_TIME_BASE;
        pos = value;
        if (_avFmtCtx->start_time != AV_NOPTS_VALUE && pos < _avFmtCtx->start_time / (double)AV_TIME_BASE) {
            pos = _avFmtCtx->start_time / (double)AV_TIME_BASE;
        }
        [self streamSeek:(int64_t)(pos * AV_TIME_BASE) rel:(int64_t)(value * AV_TIME_BASE) byBytes:0];
    }
}

- (void)seekInDecoderBufferByValue:(float) value {
    if (value > 1.0) value = 1.0;
    if (_seekByBytes || _avFmtCtx->duration <= 0) {
        uint64_t size =  avio_size(_avFmtCtx->pb);
        [self streamSeek:(size * value) rel:0 byBytes:1];
    }
}

- (void)cycleAudioStream {
    [self togglePause];
#ifdef VK_RECORDING_CAPABILITY
    [self stopRecording];
#endif
    [self cycleStreamWithType:AVMEDIA_TYPE_AUDIO index:-1];
    [self togglePause];
}

- (void)cycleAudioStreamWithStreamIndex:(int) index {
    [self togglePause];
#ifdef VK_RECORDING_CAPABILITY
    [self stopRecording];
#endif
    [self cycleStreamWithType:AVMEDIA_TYPE_AUDIO index:index];
    [self togglePause];
}

- (NSString *)codecInfoWithStreamIndex:(int) index {

    if (_avFmtCtx && (index < _avFmtCtx->nb_streams)) {
        AVStream *stream = _avFmtCtx->streams[index];
        AVCodecContext *codec = stream->codec;

        char infoCString[256];
        avcodec_string(infoCString, sizeof(infoCString), stream->codec, 1);
        NSString *strInfo = [NSString stringWithCString:infoCString encoding:NSUTF8StringEncoding];

         if (codec->codec_type == AVMEDIA_TYPE_AUDIO) {
             if (strInfo && [strInfo hasPrefix:@"Audio: "])
                 strInfo = [strInfo substringFromIndex:7];
             return strInfo;
         } else if (codec->codec_type == AVMEDIA_TYPE_VIDEO) {
             if (strInfo && [strInfo hasPrefix:@"Video: "])
                 strInfo = [strInfo substringFromIndex:7];
             return strInfo;
         } else {
             return @"";
         }
    }
    return @"";
}

- (void)updateStreamInfoWithSelectedStreamIndex:(int)index type:(int)mediaType {

    NSString *strInfo = [self codecInfoWithStreamIndex:index];
    if (mediaType == AVMEDIA_TYPE_AUDIO) {
        [_streamInfo setObject:strInfo forKey:STREAMINFO_KEY_AUDIO];
    } else if (mediaType == AVMEDIA_TYPE_VIDEO) {
        [_streamInfo setObject:strInfo forKey:STREAMINFO_KEY_VIDEO];
    } else {
        //do nothing for now..
    }
}

- (NSArray *)playableAudioStreams {
    NSMutableArray *array = [NSMutableArray array];

    for (int sIdx = 0; sIdx < _avFmtCtx->nb_streams; sIdx++) {

        AVStream *stream = _avFmtCtx->streams[sIdx];
        AVCodecContext *codec = stream->codec;

        if (codec->codec_type == AVMEDIA_TYPE_AUDIO && codec->channels > 0) {
            AVDictionaryEntry *langEntry = av_dict_get(stream->metadata, "language", NULL, 0);
            NSString *lang = @"";
            if (langEntry && langEntry->value) {
                lang = [NSString stringWithFormat:@"%s", langEntry->value];
            }
            [array addObject:@{@"index": @(sIdx), @"description": lang}];
        }
    }
    return (NSArray *)array;
}

- (NSArray *)playableVideoStreams {
    NSMutableArray *array = [NSMutableArray array];

    for (int sIdx = 0; sIdx < _avFmtCtx->nb_streams; sIdx++) {

        AVStream *stream = _avFmtCtx->streams[sIdx];
        AVCodecContext *codec = stream->codec;

        if (codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            AVDictionaryEntry *langEntry = av_dict_get(stream->metadata, "language", NULL, 0);
            NSString *lang = @"";
            if (langEntry && langEntry->value) {
                lang = [NSString stringWithFormat:@"%s", langEntry->value];
            }
            [array addObject:@{@"index": @(sIdx), @"description": lang}];
        }
    }
    return (NSArray *)array;
}

- (void)setVolumeLevel:(float)level {
    
    if (level < 0.0) {
        _volumeLevel = 0.0;
    } else if (level > 1.0) {
        _volumeLevel = 1.0;
    } else {
        _volumeLevel = level;
    }
    
    if (_audioIsOK) {
        [_aDecoder setVolumeLevel:_volumeLevel];
    }
}

- (void)setPanningLevel:(float)level {
    
    if (level < -1.0) {
        _panningLevel = -1.0;
    } else if (level > 1.0) {
        _panningLevel = 1.0;
    } else {
        _panningLevel = level;
    }
    
    if (_audioIsOK) {
        [_aDecoder setPanningLevel:_panningLevel];
    }
}

- (void)setProbeSize:(int64_t)probeSize {
    _probeSize = probeSize;
    if (_avFmtCtx) {
        _avFmtCtx->probesize = probeSize;
    }
}

- (void)setMaxAnalyzeDuration:(int64_t)maxAnalyzeDuration {
    _maxAnalyzeDuration = maxAnalyzeDuration;
    if (_avFmtCtx) {
        _avFmtCtx->max_analyze_duration = _maxAnalyzeDuration;
    }
}

- (void)setInitialPlaybackTime:(int64_t)initialPlaybackTime {
    _initialPlaybackTime = (initialPlaybackTime > 0) ? initialPlaybackTime * NSEC_PER_MSEC : AV_NOPTS_VALUE;
}

#pragma mark - Stream controllers

- (void)streamTogglePause
{
    if (_streamIsPaused) {
        [self setDecoderState:kVKDecoderStatePlaying errorCode:kVKErrorNone];
        if (_videoIsOK) {
            [_vDecoder onStreamPaused];
        }
    } else {
        [self setDecoderState:kVKDecoderStatePaused errorCode:kVKErrorNone];
    }
    
    //[self updateExternalClockPts:[self externalClock]];
    [_clockManager setClockTime:_externalClock pts:[_clockManager clockTime:_externalClock] serial:_externalClock.serial];
    _streamIsPaused = !_streamIsPaused;
    _externalClock.paused = _streamIsPaused;
    if (_videoIsOK) {
        [_vDecoder decoderClock].paused = _streamIsPaused;
    }
    if (_audioIsOK) {
        [_aDecoder decoderClock].paused = _streamIsPaused;
    }
    
}

/* seek in the stream */
- (void)streamSeek:(int64_t)pos rel:(int64_t)rel  byBytes:(int)byBytes
{
    if (!_seekRequest) {
        _seekPosition = pos;
        _seekRel = rel;
        _seekFlags &= ~AVSEEK_FLAG_BYTE;
        if (byBytes)
            _seekFlags |= AVSEEK_FLAG_BYTE;
        _seekRequest = 1;
    }
}

- (void)cycleStreamWithType:(int)type index:(int) sIndex {

    int start_index, stream_index;
    AVStream *st;

    if (!_avFmtCtx || !_avFmtCtx->nb_streams)
        return;

    if (sIndex == -1) {
        //no index is given change audio stream to next if available
        if (type == AVMEDIA_TYPE_VIDEO) {
            start_index = _lastVideoStream;
        } else {
            start_index = _lastAudioStream;
        }

        stream_index = start_index;

        for (;;) {
            if (++stream_index >= _avFmtCtx->nb_streams)
            {
                if (start_index == -1)
                    return;
                stream_index = 0;
            }
            if (stream_index == start_index)
                return;

            st = _avFmtCtx->streams[stream_index];
            if (type == st->codec->codec_type) {
                /* check that parameters are OK */
                switch (type) {
                    case AVMEDIA_TYPE_AUDIO:
                        if (st->codec->sample_rate != 0 &&
                            st->codec->channels != 0)
                            goto the_end;
                        break;
                    case AVMEDIA_TYPE_VIDEO:
                        goto the_end;
                    default:
                        break;
                }
            }
        }
    } else {
        if (sIndex < _avFmtCtx->nb_streams) {
            stream_index = sIndex;
            st = _avFmtCtx->streams[stream_index];
            if (type == st->codec->codec_type) {
                /* check that parameters are OK */
                switch (type) {
                    case AVMEDIA_TYPE_AUDIO:
                        if (st->codec->sample_rate != 0 &&
                            st->codec->channels != 0)
                            goto the_end;
                        break;
                    case AVMEDIA_TYPE_VIDEO:
                        goto the_end;
                    default:
                        break;
                }
            }
        } else {
            return;
        }
    }

the_end:

    if (type == AVMEDIA_TYPE_AUDIO) {
        [self closeAudioStream];
        VKError errAudio = kVKErrorNone;
        errAudio = [self openAudioStreamWithId:stream_index];

        if (errAudio == kVKErrorNone) {
            _audioIsOK = YES;
            _avFmtCtx->streams[stream_index]->discard = AVDISCARD_DEFAULT;
            [_vDecoder onAudioStreamCycled:_aDecoder];
            [self updateStreamInfoWithSelectedStreamIndex:stream_index type:AVMEDIA_TYPE_AUDIO];
            [_aDecoder performSelector:@selector(startAudioSystem)];
        }
    } else if (type == AVMEDIA_TYPE_VIDEO) {
        [self closeVideoStream];
        VKError errVideo = kVKErrorNone;
        errVideo = [self openVideoStreamWithId:stream_index audioIsOK:_audioIsOK];
        if (errVideo == kVKErrorNone) {
            _videoIsOK = YES;
            _avFmtCtx->streams[stream_index]->discard = AVDISCARD_DEFAULT;
            [self updateStreamInfoWithSelectedStreamIndex:stream_index type:AVMEDIA_TYPE_VIDEO];
        }
    }
    if (type == AVMEDIA_TYPE_VIDEO)
        _queueAttachmentsReq = 1;
}

#pragma clang diagnostic pop

#pragma mark - AudioSession interruption

- (void)beginInterruption {
    VKLog(kVKLogLevelDecoder, @"Begin audio interuption");
    [self togglePause];
    if (_audioIsOK) {
        [_aDecoder stopAUGraph];
    }
}

- (void)endInterruptionWithFlags:(NSUInteger)flags {
    // re-activate audio session after interruption
    NSError *error;
    if(![[AVAudioSession sharedInstance] setActive:YES error:&error]) {
        VKLog(kVKLogLevelDecoder, @"Error: Audio Session could not be activated: %@", error);
    }
    VKLog(kVKLogLevelDecoder, @"End Audio interuption");
    
    [self doSeek:[self currentTime]];
    
    if (_audioIsOK) {
        if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
            [_aDecoder performSelector:@selector(startAUGraph) withObject:nil afterDelay:0.1];
        }
    }
    
    [self togglePause];
}

- (void) interruption:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSUInteger interuptionType = (NSUInteger)[[interuptionDict valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    
    if (interuptionType == AVAudioSessionInterruptionTypeBegan) {
        [self beginInterruption];
    } else if (interuptionType == AVAudioSessionInterruptionTypeEnded) {
        [self endInterruptionWithFlags:0];
    }
}

#pragma mark - Decoder delegate & callback

- (void)setDelegate:(NSObject<VKDecoderDelegate> *)delegate {
    _delegate = delegate;
    if (_decoderState == kVKDecoderStateNone) {
        [self setDecoderState:kVKDecoderStateInitialized errorCode:kVKErrorNone];
    }
}

- (void)setDecoderStateWithData:(NSDictionary *)data {
    VKDecoderState state = (VKDecoderState)[[data objectForKey:@"state"] integerValue];
    VKError error = (VKError)[[data objectForKey:@"error"] integerValue];
    
    [self setDecoderState:state errorCode:error];
}

- (void)setDecoderState:(VKDecoderState)state errorCode:(VKError)errCode {
    
    if (_decoderState != state) {
        _decoderState = state;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if(_delegate && [_delegate respondsToSelector:@selector(decoderStateChanged:errorCode:)]) {
                [_delegate decoderStateChanged:state errorCode:errCode];
            }
            if (state == kVKDecoderStateConnected) {
#ifdef TRIAL
                [self startTrialTimer];
#endif
            }
            
        });
    }
}

#pragma mark - Application callbacks

- (void)appDidEnterBackground {
    _appIsInBackgroundNow = YES;
    VKLog(kVKLogLevelDecoder, @"Application did enter background now...");
}

- (void)appWillEnterForeground {
    _appIsInBackgroundNow = NO;
    VKLog(kVKLogLevelDecoder, @"Application will enter foreground now...");
}

#pragma mark - Reachability callback
- (void)onReachabilityChanged:(NSNotification *)notification {
    VKNetworkStatus status = [_reachability currentReachabilityStatus];

    if (!_streamInfo)
        return;

    if(status == kVKNetworkStatusReachableViaWiFi) {
        [_streamInfo setObject:TR(@"Wifi") forKey:STREAMINFO_KEY_CONNECTION];
    } else if (status == kVKNetworkStatusReachableViaWWAN) {
        [_streamInfo setObject:TR(@"3G/Edge") forKey:STREAMINFO_KEY_CONNECTION];
    }else if (status == kVKNetworkStatusNotReachable) {
        [_streamInfo setObject:TR(@"None") forKey:STREAMINFO_KEY_CONNECTION];
    }
}

#pragma mark - Decoder Utility methods

- (BOOL)isRealTime {
    if(!strcmp(_avFmtCtx->iformat->name, "rtp") ||
       !strcmp(_avFmtCtx->iformat->name, "rtsp") ||
       !strcmp(_avFmtCtx->iformat->name, "sdp"))
        return YES;
    
    if(_avFmtCtx->pb && (!strncmp(_avFmtCtx->filename, "rtp:", 4) ||
                         !strncmp(_avFmtCtx->filename, "udp:", 4)))
        return YES;
    
    return NO;
}

- (BOOL)isFileStream:(NSString *)fileName {
    if (fileName && fileName.length) {
        char *filename = (char *)[fileName UTF8String];
        char qolon = ':';//character to search
        char *found;
        
        found = strchr(filename, qolon);
        if (found) {
            size_t len = found - filename;
            if (len < 10) {
                return NO;
            }
        }
    }
    return YES;
}

#pragma mark - TRIAL Control methods

- (void)startTrialTimer {
#ifdef TRIAL
    NSLog(@"--===OOO Hello Developer, YOU ARE TESTING THE iOS VIDEOKIT TRIAL VERSION, PLEASE NOTE THAT TRIAL AND PAID VERSIONS ARE SAME EXCEPT TRIAL VERSION HAS TRIAL TEXT ON SCREEN AND 15 MINUTES PLAYING DURATION LIMITATION... OOO===---");
    
    [self stopTrialTimer];
    _timerTrial = [[NSTimer scheduledTimerWithTimeInterval:(15.0*60) target:self selector:@selector(onTimerTrialFired:) userInfo:nil repeats:NO] retain];
    [[NSRunLoop mainRunLoop] addTimer:_timerTrial forMode:NSRunLoopCommonModes];
#endif
}

- (void)stopTrialTimer {
#ifdef TRIAL
    if (_timerTrial && [_timerTrial isValid]) {
        [_timerTrial invalidate];
    }
    [_timerTrial release];
    _timerTrial = nil;
    _trialReadError = NO;
#endif
}

- (void)onTimerTrialFired:(NSTimer *)timer {
#ifdef TRIAL
    _trialReadError = YES;
#endif
}

#pragma mark - Shutdown

- (void)shutDown {
    if (_audioIsOK) {
        if (_vDecoder){
            [_vDecoder onAudioDecoderDestroyed];
        }
        [self closeAudioStream];
    }
    if (_videoIsOK) {
        [self closeVideoStream];
    }
}

- (void)destroyReachability {
    [_reachability stopNotifier];
    [_reachability release];
    _reachability = nil;
}

- (void)destroyDispatchQueues {
    dispatch_release(_readPktQueue);
}

- (void)dealloc {
    
#ifdef TRIAL
    [self stopTrialTimer];
#endif

    if (_avFmtCtx) {
        _avFmtCtx->interrupt_callback.callback = NULL;
        _avFmtCtx->interrupt_callback.opaque = NULL;
        avformat_close_input(&_avFmtCtx);
        _avFmtCtx = NULL;
        VKLog(kVKLogLevelDecoder, @"avformat_close_input");
    }

    [self destroyReachability];
    [self destroyDispatchQueues];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_streamInfo release];
    [_decodeOptions release];
    [_streamURL release];
    
    [_externalClock release];
    [_clockManager release];
    
    [_ffmpegVersion release];

    avformat_network_deinit();

    VKLog(kVKLogLevelDecoder, @"Decoder manager is deallocated...");
    [super dealloc];
}

@end

#pragma mark - decoder interrupt function

static int decode_interrupt_cb(void *decoder)
{
    if (decoder)
        return ([(VKDecodeManager *)decoder abortIsRequested] ||
                [(VKDecodeManager *)decoder willAbort]);
    return 0;
}

#pragma mark - ffmpeg locking callback function

static int lockmgr(void **mtx, enum AVLockOp op)
{
    switch(op) {
        case AV_LOCK_CREATE:
            *mtx = malloc(sizeof(pthread_mutex_t));
            if(!*mtx)
                return 1;
            return !!pthread_mutex_init(*mtx, NULL);
        case AV_LOCK_OBTAIN:
            return !!pthread_mutex_lock(*mtx);
        case AV_LOCK_RELEASE:
            return !!pthread_mutex_unlock(*mtx);
        case AV_LOCK_DESTROY:
            pthread_mutex_destroy(*mtx);
            free(*mtx);
            return 0;
    }
    return 1;
}

#pragma mark - h264 Hardware acceleration callback function

#if !TARGET_OS_TV

enum AVPixelFormat vk_get_format(struct AVCodecContext *s, const enum AVPixelFormat * fmt) {
    
    if(*fmt == AV_PIX_FMT_VIDEOTOOLBOX) {
        int errCode = av_videotoolbox_default_init(s);
        
        if(errCode == 0) {
            if (log_level != kVKLogLevelDisable) {
                printf("\n");
                printf("\n");
                printf("** Using hardware acceleration (VIDEOTOOLBOX) **\n");
                printf("\n");
            }
        }
    }
    return *fmt;
}

#endif
