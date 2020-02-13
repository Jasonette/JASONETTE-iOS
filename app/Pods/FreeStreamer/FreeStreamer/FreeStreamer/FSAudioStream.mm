/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2018 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#import "FSAudioStream.h"

#import "Reachability.h"

#include "audio_stream.h"
#include "stream_configuration.h"
#include "input_stream.h"

#import <AVFoundation/AVFoundation.h>

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>
#endif

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
static NSMutableDictionary *fsAudioStreamPrivateActiveSessions = nil;
#endif

@interface FSCacheObject : NSObject {
}

@property (strong,nonatomic) NSString *path;
@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSDictionary *attributes;
@property (nonatomic,readonly) unsigned long long fileSize;
@property (nonatomic,readonly) NSDate *modificationDate;

@end

@implementation FSCacheObject

- (unsigned long long)fileSize
{
    NSNumber *fileSizeNumber = [self.attributes objectForKey:NSFileSize];
    return [fileSizeNumber longLongValue];
}

- (NSDate *)modificationDate
{
    NSDate *date = [self.attributes objectForKey:NSFileModificationDate];
    return date;
}

@end

static NSInteger sortCacheObjects(id co1, id co2, void *keyForSorting)
{
    FSCacheObject *cached1 = (FSCacheObject *)co1;
    FSCacheObject *cached2 = (FSCacheObject *)co2;
    
    NSDate *d1 = cached1.modificationDate;
    NSDate *d2 = cached2.modificationDate;
    
    return [d1 compare:d2];
}

@implementation FSStreamConfiguration

- (id)init
{
    self = [super init];
    if (self) {
        NSMutableString *systemVersion = [[NSMutableString alloc] init];
        
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
        [systemVersion appendString:@"iOS "];
        [systemVersion appendString:[[UIDevice currentDevice] systemVersion]];
#else
        [systemVersion appendString:@"OS X"];
#endif

        self.bufferCount    = 64;
        self.bufferSize     = 8192;
        self.maxPacketDescs = 512;
        self.httpConnectionBufferSize = 8192;
        self.outputSampleRate = 44100;
        self.outputNumChannels = 2;
        self.bounceInterval    = 10;
        self.maxBounceCount    = 4;   // Max number of bufferings in bounceInterval seconds
        self.startupWatchdogPeriod = 30; // If the stream doesn't start to play in this seconds, the watchdog will fail it
#ifdef __LP64__
        /* Increase the max in-memory cache to 10 MB with newer 64 bit devices */
        self.maxPrebufferedByteCount = 10000000; // 10 MB
#else
        self.maxPrebufferedByteCount = 1000000; // 1 MB
#endif
        self.userAgent = [NSString stringWithFormat:@"FreeStreamer/%@ (%@)", freeStreamerReleaseVersion(), systemVersion];
        self.cacheEnabled = YES;
        self.seekingFromCacheEnabled = YES;
        self.automaticAudioSessionHandlingEnabled = YES;
        self.enableTimeAndPitchConversion = NO;
        self.requireStrictContentTypeChecking = YES;
        self.maxDiskCacheSize = 256000000; // 256 MB
        self.usePrebufferSizeCalculationInSeconds = YES;
        self.usePrebufferSizeCalculationInPackets = NO;
        self.requiredInitialPrebufferedPacketCount = 32;
        self.requiredPrebufferSizeInSeconds = 7;
        // With dynamic calculation, these are actually the maximum sizes, the dynamic
        // calculation may lower the sizes based on the stream bitrate
        self.requiredInitialPrebufferedByteCountForContinuousStream = 256000;
        self.requiredInitialPrebufferedByteCountForNonContinuousStream = 256000;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        if ([paths count] > 0) {
            self.cacheDirectory = [paths objectAtIndex:0];
        }
        
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 60000)
        AVAudioSession *session = [AVAudioSession sharedInstance];
        double sampleRate = session.sampleRate;
        if (sampleRate > 0) {
            self.outputSampleRate = sampleRate;
        }
        NSInteger channels = session.outputNumberOfChannels;
        if (channels > 0) {
            self.outputNumChannels = channels;
        }
#endif
            
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
        /* iOS */
            
#else
            /* OS X */
            
            self.requiredPrebufferSizeInSeconds = 3;
        
            // No need to be so concervative with the cache sizes
            self.maxPrebufferedByteCount = 16000000; // 16 MB
#endif
    }
    
    return self;
}

@end

static NSDateFormatter *statisticsDateFormatter = nil;

@implementation FSStreamStatistics

- (NSString *)snapshotTimeFormatted
{
    if (!statisticsDateFormatter) {
        statisticsDateFormatter = [[NSDateFormatter alloc] init];
        [statisticsDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    return [statisticsDateFormatter stringFromDate:self.snapshotTime];
}

- (NSString *)description
{
    return [[NSString alloc] initWithFormat:@"%@\t%lu\t%lu\t%lu",
                self.snapshotTimeFormatted,
                (unsigned long)self.audioStreamPacketCount,
                (unsigned long)self.audioQueueUsedBufferCount,
                (unsigned long)self.audioQueuePCMPacketQueueCount];
}

@end

NSString *freeStreamerReleaseVersion()
{
    NSString *version = [NSString stringWithFormat:@"%i.%i.%i",
                         FREESTREAMER_VERSION_MAJOR,
                         FREESTREAMER_VERSION_MINOR,
                         FREESTREAMER_VERSION_REVISION];
    return version;
}

NSString* const FSAudioStreamStateChangeNotification = @"FSAudioStreamStateChangeNotification";
NSString* const FSAudioStreamNotificationKey_Stream = @"stream";
NSString* const FSAudioStreamNotificationKey_State = @"state";

NSString* const FSAudioStreamErrorNotification = @"FSAudioStreamErrorNotification";
NSString* const FSAudioStreamNotificationKey_Error = @"error";
NSString* const FSAudioStreamNotificationKey_ErrorDescription = @"errorDescription";

NSString* const FSAudioStreamMetaDataNotification = @"FSAudioStreamMetaDataNotification";
NSString* const FSAudioStreamNotificationKey_MetaData = @"metadata";

class AudioStreamStateObserver : public astreamer::Audio_Stream_Delegate
{
public:
    astreamer::Audio_Stream *source;
    FSAudioStreamPrivate *priv;
    
    void audioStreamErrorOccurred(int errorCode, CFStringRef errorDescription);
    void audioStreamStateChanged(astreamer::Audio_Stream::State state);
    void audioStreamMetaDataAvailable(std::map<CFStringRef,CFStringRef> metaData);
    void samplesAvailable(AudioBufferList *samples, UInt32 frames, AudioStreamPacketDescription description);
    void bitrateAvailable();
};

/*
 * ===============================================================
 * FSAudioStream private implementation
 * ===============================================================
 */

@interface FSAudioStreamPrivate : NSObject {
    astreamer::Audio_Stream *_audioStream;
    NSURL *_url;
	AudioStreamStateObserver *_observer;
    NSString *_defaultContentType;
    Reachability *_reachability;
    FSSeekByteOffset _lastSeekByteOffset;
    BOOL _wasPaused;
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
    UIBackgroundTaskIdentifier _backgroundTask;
#endif
}

@property (nonatomic,assign) NSURL *url;
@property (nonatomic,assign) BOOL strictContentTypeChecking;
@property (nonatomic,assign) NSString *defaultContentType;
@property (readonly) NSString *contentType;
@property (readonly) NSString *suggestedFileExtension;
@property (nonatomic, assign) UInt64 defaultContentLength;
@property (readonly) UInt64 contentLength;
@property (nonatomic,assign) NSURL *outputFile;
@property (nonatomic,assign) BOOL wasInterrupted;
@property (nonatomic,assign) BOOL wasDisconnected;
@property (nonatomic,assign) BOOL wasContinuousStream;
@property (nonatomic,assign) BOOL internetConnectionAvailable;
@property (nonatomic,assign) NSUInteger maxRetryCount;
@property (nonatomic,assign) NSUInteger retryCount;
@property (readonly) FSStreamStatistics *statistics;
@property (readonly) FSLevelMeterState levels;
@property (readonly) size_t prebufferedByteCount;
@property (readonly) FSSeekByteOffset currentSeekByteOffset;
@property (readonly) float bitRate;
@property (readonly) FSStreamConfiguration *configuration;
@property (readonly) NSString *formatDescription;
@property (readonly) BOOL cached;
@property (copy) void (^onCompletion)();
@property (copy) void (^onStateChange)(FSAudioStreamState state);
@property (copy) void (^onMetaDataAvailable)(NSDictionary *metaData);
@property (copy) void (^onFailure)(FSAudioStreamError error, NSString *errorDescription);
@property (nonatomic,unsafe_unretained) id<FSPCMAudioStreamDelegate> delegate;
@property (nonatomic,unsafe_unretained) FSAudioStream *stream;

- (AudioStreamStateObserver *)streamStateObserver;

- (void)endBackgroundTask;

- (void)reachabilityChanged:(NSNotification *)note;
- (void)interruptionOccurred:(NSNotification *)notification;

- (void)notifyPlaybackStopped;
- (void)notifyPlaybackBuffering;
- (void)notifyPlaybackPlaying;
- (void)notifyPlaybackPaused;
- (void)notifyPlaybackSeeking;
- (void)notifyPlaybackEndOfFile;
- (void)notifyPlaybackFailed;
- (void)notifyPlaybackCompletion;
- (void)notifyPlaybackUnknownState;
- (void)notifyRetryingStarted;
- (void)notifyRetryingSucceeded;
- (void)notifyRetryingFailed;
- (void)notifyStateChange:(FSAudioStreamState)streamerState;

- (void)attemptRestart;
- (void)expungeCache;
- (void)play;
- (void)playFromURL:(NSURL*)url;
- (void)playFromOffset:(FSSeekByteOffset)offset;
- (void)stop;
- (BOOL)isPlaying;
- (void)pause;
- (void)rewind:(unsigned)seconds;
- (void)seekToOffset:(float)offset;
- (float)currentVolume;
- (unsigned long long)totalCachedObjectsSize;
- (void)setVolume:(float)volume;
- (void)setPlayRate:(float)playRate;
- (astreamer::AS_Playback_Position)playbackPosition;
- (UInt64)audioDataByteCount;
- (float)durationInSeconds;
- (void)bitrateAvailable;
@end

@implementation FSAudioStreamPrivate

-(id)init
{
    NSAssert([NSThread isMainThread], @"FSAudioStreamPrivate.init needs to be called in the main thread");
    
    if (self = [super init]) {
        _url = nil;
        
        _observer = new AudioStreamStateObserver();
        _observer->priv = self;
       
        _audioStream = new astreamer::Audio_Stream();
        _observer->source = _audioStream;

        _audioStream->m_delegate = _observer;
        
        _reachability = nil;
        
        _delegate = nil;
        
        _maxRetryCount = 3;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
        _backgroundTask = UIBackgroundTaskInvalid;
        
        @synchronized (self) {
            if (!fsAudioStreamPrivateActiveSessions) {
                fsAudioStreamPrivateActiveSessions = [[NSMutableDictionary alloc] init];
            }
        }
        
        if (self.configuration.automaticAudioSessionHandlingEnabled) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        }
#endif
        
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 60000)
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(interruptionOccurred:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:nil];
#endif
    }
    return self;
}

- (void)dealloc
{
    NSAssert([NSThread isMainThread], @"FSAudioStreamPrivate.dealloc needs to be called in the main thread");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self stop];
    
    _delegate = nil;
    
    delete _audioStream;
    _audioStream = nil;
    delete _observer;
    _observer = nil;
    
    // Clean up the disk cache.
    
    if (!self.configuration.cacheEnabled) {
        // Don't clean up if cache not enabled
        return;
    }
    
    unsigned long long totalCacheSize = 0;
    
    NSMutableArray *cachedFiles = [[NSMutableArray alloc] init];
    
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.configuration.cacheDirectory error:nil]) {
        if ([file hasPrefix:@"FSCache-"]) {
            FSCacheObject *cacheObj = [[FSCacheObject alloc] init];
            cacheObj.name = file;
            cacheObj.path = [NSString stringWithFormat:@"%@/%@", self.configuration.cacheDirectory, cacheObj.name];
            cacheObj.attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:cacheObj.path error:nil];
            
            totalCacheSize += [cacheObj fileSize];
            
            if (![cacheObj.name hasSuffix:@".metadata"]) {
                [cachedFiles addObject:cacheObj];
            }
        }
    }
    
    // Sort by the modification date.
    // In this way the older content will be removed first from the cache.
    [cachedFiles sortUsingFunction:sortCacheObjects context:NULL];
    
    for (FSCacheObject *cacheObj in cachedFiles) {
        if (totalCacheSize < self.configuration.maxDiskCacheSize) {
            break;
        }
        
        FSCacheObject *cachedMetaData = [[FSCacheObject alloc] init];
        cachedMetaData.name = [NSString stringWithFormat:@"%@.metadata", cacheObj.name];
        cachedMetaData.path = [NSString stringWithFormat:@"%@/%@", self.configuration.cacheDirectory, cachedMetaData.name];
        cachedMetaData.attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:cachedMetaData.path error:nil];
        
        if (![[NSFileManager defaultManager] removeItemAtPath:cachedMetaData.path error:nil]) {
            continue;
        }
        totalCacheSize -= [cachedMetaData fileSize];
                
        if (![[NSFileManager defaultManager] removeItemAtPath:cacheObj.path error:nil]) {
            continue;
        }
        totalCacheSize -= [cacheObj fileSize];
    }
    
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
    @synchronized (self) {
        [fsAudioStreamPrivateActiveSessions removeObjectForKey:[NSNumber numberWithUnsignedLong:(unsigned long)self]];
        
        if ([fsAudioStreamPrivateActiveSessions count] == 0) {
            if (self.configuration.automaticAudioSessionHandlingEnabled) {
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 60000)
                [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
#else
                [[AVAudioSession sharedInstance] setActive:NO error:nil];
#endif
            }
        }
    }
#endif
}

- (void)endBackgroundTask
{
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
    if (_backgroundTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
        _backgroundTask = UIBackgroundTaskInvalid;
    }
#endif
}

- (AudioStreamStateObserver *)streamStateObserver
{
    return _observer;
}

- (void)setUrl:(NSURL *)url
{
    if ([self isPlaying]) {
        [self stop];
    }
    
    @synchronized (self) {
        if ([url isEqual:_url]) {
            return;
        }
        
        _url = [url copy];
        
        _audioStream->setUrl((__bridge CFURLRef)_url);
    }
    
    if ([self isPlaying]) {
        [self play];
    }
}

- (NSURL*)url
{
    if (!_url) {
        return nil;
    }
    
    NSURL *copyOfURL = [_url copy];
    return copyOfURL;
}

- (void)setStrictContentTypeChecking:(BOOL)strictContentTypeChecking
{
    _audioStream->setStrictContentTypeChecking(strictContentTypeChecking);
}

- (BOOL)strictContentTypeChecking
{
    return _audioStream->strictContentTypeChecking();
}

- (void)playFromURL:(NSURL*)url
{
   [self setUrl:url];
   [self play];
}

- (void)playFromOffset:(FSSeekByteOffset)offset
{
    _wasPaused = NO;
    
    if (_audioStream->isPreloading()) {
        _audioStream->seekToOffset(offset.position);
        _audioStream->setPreloading(false);
    } else {
        astreamer::Input_Stream_Position position;
        position.start = offset.start;
        position.end   = offset.end;
        
        _audioStream->open(&position);
        
        _audioStream->setSeekOffset(offset.position);
        _audioStream->setContentLength(offset.end);
    }
    
    if (!_reachability) {
        _reachability = [Reachability reachabilityForInternetConnection];
        
        [_reachability startNotifier];
    }
}

- (void)setDefaultContentType:(NSString *)defaultContentType
{
    if (defaultContentType) {
        _defaultContentType = [defaultContentType copy];
        _audioStream->setDefaultContentType((__bridge CFStringRef)_defaultContentType);
    } else {
        _audioStream->setDefaultContentType(NULL);
    }
}

- (NSString*)defaultContentType
{
    if (!_defaultContentType) {
        return nil;
    }
    
    NSString *copyOfDefaultContentType = [_defaultContentType copy];
    return copyOfDefaultContentType;
}

- (NSString*)contentType
{
    CFStringRef c = _audioStream->contentType();
    if (c) {
        return CFBridgingRelease(CFStringCreateCopy(kCFAllocatorDefault, c));
    }
    return nil;
}

- (NSString*)suggestedFileExtension
{
    NSString *contentType = [self contentType];
    NSString *suggestedFileExtension = nil;
    
    if ([contentType isEqualToString:@"audio/mpeg"]) {
        suggestedFileExtension = @"mp3";
    } else if ([contentType isEqualToString:@"audio/x-wav"]) {
        suggestedFileExtension = @"wav";
    } else if ([contentType isEqualToString:@"audio/x-aifc"]) {
        suggestedFileExtension = @"aifc";
    } else if ([contentType isEqualToString:@"audio/x-aiff"]) {
        suggestedFileExtension = @"aiff";
    } else if ([contentType isEqualToString:@"audio/x-m4a"]) {
        suggestedFileExtension = @"m4a";
    } else if ([contentType isEqualToString:@"audio/mp4"]) {
        suggestedFileExtension = @"mp4";
    } else if ([contentType isEqualToString:@"audio/x-caf"]) {
        suggestedFileExtension = @"caf";
    }
    else if ([contentType isEqualToString:@"audio/aac"] ||
             [contentType isEqualToString:@"audio/aacp"]) {
        suggestedFileExtension = @"aac";
    }
    return suggestedFileExtension;
}

- (UInt64)defaultContentLength
{
    return _audioStream->defaultContentLength();
}

- (UInt64)contentLength
{
    return _audioStream->contentLength();
}

- (NSURL*)outputFile
{
    CFURLRef url = _audioStream->outputFile();
    if (url) {
        NSURL *u = (__bridge NSURL*)url;
        return [u copy];
    }
    return nil;
}

- (void)setOutputFile:(NSURL *)outputFile
{
    if (!outputFile) {
        _audioStream->setOutputFile(NULL);
        return;
    }
    NSURL *copyOfURL = [outputFile copy];
    _audioStream->setOutputFile((__bridge CFURLRef)copyOfURL);
}

- (FSStreamStatistics *)statistics
{
    FSStreamStatistics *stats = [[FSStreamStatistics alloc] init];
    
    stats.snapshotTime                  = [[NSDate alloc] init];
    stats.audioStreamPacketCount        = _audioStream->playbackDataCount();
    
    return stats;
}

- (FSLevelMeterState)levels
{
    AudioQueueLevelMeterState aqLevels = _audioStream->levels();
    
    FSLevelMeterState l;
    
    l.averagePower = aqLevels.mAveragePower;
    l.peakPower    = aqLevels.mPeakPower;
    
    return l;
}

- (size_t)prebufferedByteCount
{
    return _audioStream->cachedDataSize();
}

- (FSSeekByteOffset)currentSeekByteOffset
{
    FSSeekByteOffset offset;
    offset.start    = 0;
    offset.end      = 0;
    offset.position = 0;
    
    // If continuous
    if (!([self durationInSeconds] > 0)) {
        return offset;
    }
    
    offset.position = _audioStream->playbackPosition().offset;
    
    astreamer::Input_Stream_Position httpStreamPos = _audioStream->streamPositionForOffset(offset.position);
    
    offset.start = httpStreamPos.start;
    offset.end   = httpStreamPos.end;
    
    return offset;
}

- (float)bitRate
{
    return _audioStream->bitrate();
}

- (FSStreamConfiguration *)configuration
{
    FSStreamConfiguration *config = [[FSStreamConfiguration alloc] init];
    
    astreamer::Stream_Configuration *c = astreamer::Stream_Configuration::configuration();
    
    config.bufferCount              = c->bufferCount;
    config.bufferSize               = c->bufferSize;
    config.maxPacketDescs           = c->maxPacketDescs;
    config.httpConnectionBufferSize = c->httpConnectionBufferSize;
    config.outputSampleRate         = c->outputSampleRate;
    config.outputNumChannels        = c->outputNumChannels;
    config.bounceInterval           = c->bounceInterval;
    config.maxBounceCount           = c->maxBounceCount;
    config.startupWatchdogPeriod    = c->startupWatchdogPeriod;
    config.maxPrebufferedByteCount  = c->maxPrebufferedByteCount;
    config.usePrebufferSizeCalculationInSeconds = c->usePrebufferSizeCalculationInSeconds;
    config.usePrebufferSizeCalculationInPackets = c->usePrebufferSizeCalculationInPackets;
    config.requiredInitialPrebufferedByteCountForContinuousStream = c->requiredInitialPrebufferedByteCountForContinuousStream;
    config.requiredInitialPrebufferedByteCountForNonContinuousStream = c->requiredInitialPrebufferedByteCountForNonContinuousStream;
    config.requiredPrebufferSizeInSeconds = c->requiredPrebufferSizeInSeconds;
    config.requiredInitialPrebufferedPacketCount = c->requiredInitialPrebufferedPacketCount;
    config.cacheEnabled             = c->cacheEnabled;
    config.seekingFromCacheEnabled  = c->seekingFromCacheEnabled;
    config.automaticAudioSessionHandlingEnabled = c->automaticAudioSessionHandlingEnabled;
    config.enableTimeAndPitchConversion = c->enableTimeAndPitchConversion;
    config.requireStrictContentTypeChecking = c->requireStrictContentTypeChecking;
    config.maxDiskCacheSize         = c->maxDiskCacheSize;
    
    if (c->userAgent) {
        // Let the Objective-C side handle the memory for the copy of the original user-agent
        config.userAgent = (__bridge_transfer NSString *)CFStringCreateCopy(kCFAllocatorDefault, c->userAgent);
    }
    
    if (c->cacheDirectory) {
        config.cacheDirectory = (__bridge_transfer NSString *)CFStringCreateCopy(kCFAllocatorDefault, c->cacheDirectory);
    }
    
    if (c->predefinedHttpHeaderValues) {
        config.predefinedHttpHeaderValues = (__bridge_transfer NSDictionary *)CFDictionaryCreateCopy(kCFAllocatorDefault, c->predefinedHttpHeaderValues);
    }

    return config;
}

- (NSString *)formatDescription
{
    return CFBridgingRelease(_audioStream->sourceFormatDescription());
}

- (BOOL)cached
{
    BOOL cachedFileExists = NO;
    
    if (self.url) {
        NSString *cacheIdentifier = (NSString*)CFBridgingRelease(_audioStream->createCacheIdentifierForURL((__bridge CFURLRef)self.url));
        
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@.metadata", self.configuration.cacheDirectory, cacheIdentifier];
        
        cachedFileExists = [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
    }
    
    return cachedFileExists;
}

- (void)reachabilityChanged:(NSNotification *)note
{
    NSAssert([NSThread isMainThread], @"FSAudioStreamPrivate.reachabilityChanged needs to be called in the main thread");
    
    Reachability *reach = [note object];
    NetworkStatus netStatus = [reach currentReachabilityStatus];
    self.internetConnectionAvailable = (netStatus == ReachableViaWiFi || netStatus == ReachableViaWWAN);
    
    if ([self isPlaying] && !self.internetConnectionAvailable) {
        self.wasDisconnected = YES;
        
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
        NSLog(@"FSAudioStream: Error: Internet connection disconnected while playing a stream.");
#endif
    }
    
    if (self.wasDisconnected && self.internetConnectionAvailable) {
        self.wasDisconnected = NO;
        
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
        NSLog(@"FSAudioStream: Internet connection available again.");
#endif
        [self attemptRestart];
    }
}

- (void)interruptionOccurred:(NSNotification *)notification
{
    NSAssert([NSThread isMainThread], @"FSAudioStreamPrivate.interruptionOccurred needs to be called in the main thread");
    
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 60000)
    NSNumber *interruptionType = [[notification userInfo] valueForKey:AVAudioSessionInterruptionTypeKey];
    NSNumber *interruptionResume = [[notification userInfo] valueForKey:AVAudioSessionInterruptionOptionKey];
    if ([interruptionType intValue] == AVAudioSessionInterruptionTypeBegan) {
        if ([self isPlaying] && !_wasPaused) {
            self.wasInterrupted = YES;
            // Continuous streams do not have a duration.
            self.wasContinuousStream = !([self durationInSeconds] > 0);
            
            if (self.wasContinuousStream) {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
                NSLog(@"FSAudioStream: Interruption began. Continuous stream. Stopping the stream.");
#endif
                [self stop];
            } else {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
                NSLog(@"FSAudioStream: Interruption began. Non-continuous stream. Stopping the stream and saving the offset.");
#endif
                _lastSeekByteOffset = [self currentSeekByteOffset];
                [self stop];
            }
        }
    } else if ([interruptionType intValue] == AVAudioSessionInterruptionTypeEnded) {
        if (self.wasInterrupted) {
            self.wasInterrupted = NO;
            
            if ([interruptionResume intValue] == AVAudioSessionInterruptionOptionShouldResume) {
                @synchronized (self) {
                    if (self.configuration.automaticAudioSessionHandlingEnabled) {
                        [[AVAudioSession sharedInstance] setActive:YES error:nil];
                    }
                    fsAudioStreamPrivateActiveSessions[[NSNumber numberWithUnsignedLong:(unsigned long)self]] = @"";
                }
                
                if (self.wasContinuousStream) {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
                    NSLog(@"FSAudioStream: Interruption ended. Continuous stream. Starting the playback.");
#endif
                    /*
                     * Resume playing.
                     */
                    [self play];
                } else {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
                    NSLog(@"FSAudioStream: Interruption ended. Continuous stream. Playing from the offset");
#endif
                    /*
                     * Resume playing.
                     */
                   [self playFromOffset:_lastSeekByteOffset];
                }
            } else {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
                NSLog(@"FSAudioStream: Interruption ended. Continuous stream. Not resuming.");
#endif
            }
        }
    }
#endif
}

- (void)notifyPlaybackStopped
{
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
    @synchronized (self) {
        [fsAudioStreamPrivateActiveSessions removeObjectForKey:[NSNumber numberWithUnsignedLong:(unsigned long)self]];
        
        if ([fsAudioStreamPrivateActiveSessions count] == 0) {
            if (self.configuration.automaticAudioSessionHandlingEnabled) {
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 60000)
                [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
#else
                [[AVAudioSession sharedInstance] setActive:NO error:nil];
#endif
            }
        }
    }
#endif
    
    [self notifyStateChange:kFsAudioStreamStopped];
}

- (void)notifyPlaybackBuffering
{
    self.internetConnectionAvailable = YES;
    [self notifyStateChange:kFsAudioStreamBuffering];
}

- (void)notifyPlaybackPlaying
{
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
    @synchronized (self) {
        if (self.configuration.automaticAudioSessionHandlingEnabled) {
            [[AVAudioSession sharedInstance] setActive:YES error:nil];
        }
        fsAudioStreamPrivateActiveSessions[[NSNumber numberWithUnsignedLong:(unsigned long)self]] = @"";
    }
#endif
    if (self.retryCount > 0) {
        [NSTimer scheduledTimerWithTimeInterval:0.1
                                         target:self
                                       selector:@selector(notifyRetryingSucceeded)
                                       userInfo:nil
                                        repeats:NO];
    }
    self.retryCount = 0;
    [self notifyStateChange:kFsAudioStreamPlaying];
}

- (void)notifyPlaybackPaused
{
    [self notifyStateChange:kFsAudioStreamPaused];
}

- (void)notifyPlaybackSeeking
{
    [self notifyStateChange:kFsAudioStreamSeeking];
}

- (void)notifyPlaybackEndOfFile
{
    [self notifyStateChange:kFSAudioStreamEndOfFile];
}

- (void)notifyPlaybackFailed
{
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
    @synchronized (self) {
        [fsAudioStreamPrivateActiveSessions removeObjectForKey:[NSNumber numberWithUnsignedLong:(unsigned long)self]];
        
        if ([fsAudioStreamPrivateActiveSessions count] == 0) {
            if (self.configuration.automaticAudioSessionHandlingEnabled) {
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 60000)
                [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
#else
                [[AVAudioSession sharedInstance] setActive:NO error:nil];
#endif
            }
        }
    }
#endif
    
    [self notifyStateChange:kFsAudioStreamFailed];
}

- (void)notifyPlaybackCompletion
{
    [self notifyStateChange:kFsAudioStreamPlaybackCompleted];
    
    if (self.onCompletion) {
        self.onCompletion();
    }
}

- (void)notifyPlaybackUnknownState
{
    [self notifyStateChange:kFsAudioStreamUnknownState];
}

- (void)notifyRetryingStarted
{
    [self notifyStateChange:kFsAudioStreamRetryingStarted];
}

- (void)notifyRetryingSucceeded
{
    [self notifyStateChange:kFsAudioStreamRetryingSucceeded];
}

- (void)notifyRetryingFailed
{
    [self notifyStateChange:kFsAudioStreamRetryingFailed];
}

- (void)notifyStateChange:(FSAudioStreamState)streamerState
{
    if (self.onStateChange) {
        self.onStateChange(streamerState);
    }
    
    NSDictionary *userInfo = @{FSAudioStreamNotificationKey_State: [NSNumber numberWithInt:streamerState],
                               FSAudioStreamNotificationKey_Stream: [NSValue valueWithPointer:_audioStream]};
    NSNotification *notification = [NSNotification notificationWithName:FSAudioStreamStateChangeNotification object:self.stream userInfo:userInfo];
    
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)preload
{
    _audioStream->setPreloading(true);
    
    _audioStream->open();
}

- (void)attemptRestart
{
    if (_audioStream->isPreloading()) {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
        NSLog(@"FSAudioStream: Stream is preloading. Not attempting a restart");
#endif
        return;
    }
    
    if (_wasPaused) {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
        NSLog(@"FSAudioStream: Stream was paused. Not attempting a restart");
#endif
        return;
    }
    
    if (!self.internetConnectionAvailable) {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
        NSLog(@"FSAudioStream: Internet connection not available. Not attempting a restart");
#endif
        return;
    }
    
    if (self.retryCount >= self.maxRetryCount) {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
        NSLog(@"FSAudioStream: Retry count %lu. Giving up.", (unsigned long)self.retryCount);
#endif
        [NSTimer scheduledTimerWithTimeInterval:0.1
                                         target:self
                                       selector:@selector(notifyRetryingFailed)
                                       userInfo:nil
                                        repeats:NO];
        return;
    }
    
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
    NSLog(@"FSAudioStream: Attempting restart.");
#endif
    
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self
                                   selector:@selector(notifyRetryingStarted)
                                   userInfo:nil
                                    repeats:NO];
    
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(play)
                                   userInfo:nil
                                    repeats:NO];
    
    self.retryCount++;
}

- (void)expungeCache
{
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.configuration.cacheDirectory error:nil]) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", self.configuration.cacheDirectory, file];
        
        if ([file hasPrefix:@"FSCache-"]) {
            if (![[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil]) {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
                NSLog(@"Failed expunging %@ from the cache", fullPath);
#endif
            }
        }
    }
}

- (void)play
{
    _wasPaused = NO;

    if (_audioStream->isPreloading()) {
        _audioStream->startCachedDataPlayback();
        
        return;
    }
    
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
    [self endBackgroundTask];
    
    _backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
#endif
    
    _audioStream->open();

    if (!_reachability) {
        _reachability = [Reachability reachabilityForInternetConnection];
        
        [_reachability startNotifier];
    }
}

- (void)stop
{
    _audioStream->close(true);
    
    [self endBackgroundTask];
    
    [_reachability stopNotifier];
    _reachability = nil;
}

- (BOOL)isPlaying
{
    const astreamer::Audio_Stream::State currentState = _audioStream->state();
    
    return (currentState == astreamer::Audio_Stream::PLAYING ||
            currentState == astreamer::Audio_Stream::END_OF_FILE);
}

- (void)pause
{
    _wasPaused = YES;
    _audioStream->pause();
}

- (void)rewind:(unsigned int)seconds
{
    if (([self durationInSeconds] > 0)) {
        // Rewinding only possible for continuous streams
        return;
    }
    
    const float originalVolume = [self currentVolume];
    
    // Set volume to 0 to avoid glitches
    _audioStream->setVolume(0);
    
    _audioStream->rewind(seconds);
    
    __weak FSAudioStreamPrivate *weakSelf = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        FSAudioStreamPrivate *strongSelf = weakSelf;
        
        // Return the original volume back
        strongSelf->_audioStream->setVolume(originalVolume);
    });
}

- (void)seekToOffset:(float)offset
{
    _audioStream->seekToOffset(offset);
}

- (float)currentVolume
{
    return _audioStream->currentVolume();
}

- (unsigned long long)totalCachedObjectsSize
{
    unsigned long long totalCacheSize = 0;
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.configuration.cacheDirectory error:nil]) {
        if ([file hasPrefix:@"FSCache-"]) {
            NSString *fullPath = [NSString stringWithFormat:@"%@/%@", self.configuration.cacheDirectory, file];
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
        
            totalCacheSize += [[attributes objectForKey:NSFileSize] longLongValue];
        }
    }
    return totalCacheSize;
}

- (void)setVolume:(float)volume
{
    _audioStream->setVolume(volume);
}

- (void)setPlayRate:(float)playRate
{
    _audioStream->setPlayRate(playRate);
}

- (astreamer::AS_Playback_Position)playbackPosition
{
    return _audioStream->playbackPosition();
}

- (UInt64)audioDataByteCount
{
    return _audioStream->audioDataByteCount();
}

- (float)durationInSeconds
{
    return _audioStream->durationInSeconds();
}

- (void)bitrateAvailable
{
    if (!self.configuration.usePrebufferSizeCalculationInSeconds) {
        return;
    }
    
    float bitrate = (int)_audioStream->bitrate();
    
    if (!(bitrate > 0)) {
        // No bitrate provided, use the defaults
        return;
    }
    
    const Float64 bufferSizeForSecond = bitrate / 8.0;
    
    int bufferSize = (bufferSizeForSecond * self.configuration.requiredPrebufferSizeInSeconds);
    
    // Check that we still got somewhat sane buffer size
    if (bufferSize < 50000) {
        bufferSize = 50000;
    }
    
    if (!([self durationInSeconds] > 0)) {
        // continuous
        if (bufferSize > self.configuration.requiredInitialPrebufferedByteCountForContinuousStream) {
            bufferSize = self.configuration.requiredInitialPrebufferedByteCountForContinuousStream;
        }
    } else {
        if (bufferSize > self.configuration.requiredInitialPrebufferedByteCountForNonContinuousStream) {
            bufferSize = self.configuration.requiredInitialPrebufferedByteCountForNonContinuousStream;
        }
    }
    
    // Update the configuration
    self.configuration.requiredInitialPrebufferedByteCountForContinuousStream = bufferSize;
    self.configuration.requiredInitialPrebufferedByteCountForNonContinuousStream = bufferSize;

    astreamer::Stream_Configuration *c = astreamer::Stream_Configuration::configuration();
    
    c->requiredInitialPrebufferedByteCountForContinuousStream = bufferSize;
    c->requiredInitialPrebufferedByteCountForNonContinuousStream = bufferSize;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"[FreeStreamer %@] URL: %@\nbufferCount: %i\nbufferSize: %i\nmaxPacketDescs: %i\nhttpConnectionBufferSize: %i\noutputSampleRate: %f\noutputNumChannels: %ld\nbounceInterval: %i\nmaxBounceCount: %i\nstartupWatchdogPeriod: %i\nmaxPrebufferedByteCount: %i\nformat: %@\nbit rate: %f\nuserAgent: %@\ncacheDirectory: %@\npredefinedHttpHeaderValues: %@\ncacheEnabled: %@\nseekingFromCacheEnabled: %@\nautomaticAudioSessionHandlingEnabled: %@\nenableTimeAndPitchConversion: %@\nrequireStrictContentTypeChecking: %@\nmaxDiskCacheSize: %i\nusePrebufferSizeCalculationInSeconds: %@\nusePrebufferSizeCalculationInPackets: %@\nrequiredPrebufferSizeInSeconds: %f\nrequiredInitialPrebufferedByteCountForContinuousStream: %i\nrequiredInitialPrebufferedByteCountForNonContinuousStream: %i\nrequiredInitialPrebufferedPacketCount: %i",
            freeStreamerReleaseVersion(),
            self.url,
            self.configuration.bufferCount,
            self.configuration.bufferSize,
            self.configuration.maxPacketDescs,
            self.configuration.httpConnectionBufferSize,
            self.configuration.outputSampleRate,
            self.configuration.outputNumChannels,
            self.configuration.bounceInterval,
            self.configuration.maxBounceCount,
            self.configuration.startupWatchdogPeriod,
            self.configuration.maxPrebufferedByteCount,
            self.formatDescription,
            self.bitRate,
            self.configuration.userAgent,
            self.configuration.cacheDirectory,
            self.configuration.predefinedHttpHeaderValues,
            (self.configuration.cacheEnabled ? @"YES" : @"NO"),
            (self.configuration.seekingFromCacheEnabled ? @"YES" : @"NO"),
            (self.configuration.automaticAudioSessionHandlingEnabled ? @"YES" : @"NO"),
            (self.configuration.enableTimeAndPitchConversion ? @"YES" : @"NO"),
            (self.configuration.requireStrictContentTypeChecking ? @"YES" : @"NO"),
            self.configuration.maxDiskCacheSize,
            (self.configuration.usePrebufferSizeCalculationInSeconds ? @"YES" : @"NO"),
            (self.configuration.usePrebufferSizeCalculationInPackets ? @"YES" : @"NO"),
            self.configuration.requiredPrebufferSizeInSeconds,
            self.configuration.requiredInitialPrebufferedByteCountForContinuousStream,
            self.configuration.requiredInitialPrebufferedByteCountForNonContinuousStream,
            self.configuration.requiredInitialPrebufferedPacketCount];
}

@end

/*
 * ===============================================================
 * FSAudioStream public implementation, merely wraps the
 * private class.
 * ===============================================================
 */

@implementation FSAudioStream

-(id)init
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.init needs to be called in the main thread");
    
    FSStreamConfiguration *defaultConfiguration = [[FSStreamConfiguration alloc] init];
    
    if (self = [self initWithConfiguration:defaultConfiguration]) {
    }
    return self;
}

- (id)initWithUrl:(NSURL *)url
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.initWithURL needs to be called in the main thread");
    
    if (self = [self init]) {
        _private.url = url;
    }
    return self;
}

- (id)initWithConfiguration:(FSStreamConfiguration *)configuration
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.initWithConfiguration needs to be called in the main thread");
    
    if (self = [super init]) {
        astreamer::Stream_Configuration *c = astreamer::Stream_Configuration::configuration();
        
        c->bufferCount              = configuration.bufferCount;
        c->bufferSize               = configuration.bufferSize;
        c->maxPacketDescs           = configuration.maxPacketDescs;
        c->httpConnectionBufferSize = configuration.httpConnectionBufferSize;
        c->outputSampleRate         = configuration.outputSampleRate;
        c->outputNumChannels        = configuration.outputNumChannels;
        c->maxBounceCount           = configuration.maxBounceCount;
        c->bounceInterval           = configuration.bounceInterval;
        c->startupWatchdogPeriod    = configuration.startupWatchdogPeriod;
        c->maxPrebufferedByteCount  = configuration.maxPrebufferedByteCount;
        c->usePrebufferSizeCalculationInSeconds = configuration.usePrebufferSizeCalculationInSeconds;
        c->usePrebufferSizeCalculationInPackets = configuration.usePrebufferSizeCalculationInPackets;
        c->cacheEnabled             = configuration.cacheEnabled;
        c->seekingFromCacheEnabled  = configuration.seekingFromCacheEnabled;
        c->automaticAudioSessionHandlingEnabled = configuration.automaticAudioSessionHandlingEnabled;
        c->enableTimeAndPitchConversion = configuration.enableTimeAndPitchConversion;
        c->requireStrictContentTypeChecking = configuration.requireStrictContentTypeChecking;
        c->maxDiskCacheSize         = configuration.maxDiskCacheSize;
        c->requiredInitialPrebufferedByteCountForContinuousStream = configuration.requiredInitialPrebufferedByteCountForContinuousStream;
        c->requiredInitialPrebufferedByteCountForNonContinuousStream = configuration.requiredInitialPrebufferedByteCountForNonContinuousStream;
        c->requiredPrebufferSizeInSeconds = configuration.requiredPrebufferSizeInSeconds;
        c->requiredInitialPrebufferedPacketCount = configuration.requiredInitialPrebufferedPacketCount;
        
        if (c->userAgent) {
            CFRelease(c->userAgent);
        }
        c->userAgent = CFStringCreateCopy(kCFAllocatorDefault, (__bridge CFStringRef)configuration.userAgent);
        
        if (c->cacheDirectory) {
            CFRelease(c->cacheDirectory);
        }
        if (configuration.cacheDirectory) {
            c->cacheDirectory = CFStringCreateCopy(kCFAllocatorDefault, (__bridge CFStringRef)configuration.cacheDirectory);
        } else {
            c->cacheDirectory = NULL;
        }
        
        if (c->predefinedHttpHeaderValues) {
            CFRelease(c->predefinedHttpHeaderValues);
        }
        if (configuration.predefinedHttpHeaderValues) {
            c->predefinedHttpHeaderValues = CFDictionaryCreateCopy(kCFAllocatorDefault, (__bridge CFDictionaryRef)configuration.predefinedHttpHeaderValues);
        } else {
            c->predefinedHttpHeaderValues = NULL;
        }
        
        _private = [[FSAudioStreamPrivate alloc] init];
        _private.stream = self;
    }
    return self;
}

- (void)dealloc
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.dealloc needs to be called in the main thread");
    
    AudioStreamStateObserver *observer = [_private streamStateObserver];
    
    // Break the cyclic loop so that dealloc() may be called
    observer->priv = nil;
    
    _private.stream = nil;
    _private.delegate = nil;
    
    _private = nil;
}

- (void)setUrl:(NSURL *)url
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.setUrl needs to be called in the main thread");
    
    [_private setUrl:url];
}

- (NSURL*)url
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.url needs to be called in the main thread");
    
    return [_private url];
}

- (void)setStrictContentTypeChecking:(BOOL)strictContentTypeChecking
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.setStrictContentTypeChecking needs to be called in the main thread");
    
    [_private setStrictContentTypeChecking:strictContentTypeChecking];
}

- (BOOL)strictContentTypeChecking
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.strictContentTypeChecking needs to be called in the main thread");
    
    return [_private strictContentTypeChecking];
}

- (NSURL*)outputFile
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.outputFile needs to be called in the main thread");
    
    return [_private outputFile];
}

- (void)setOutputFile:(NSURL *)outputFile
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.setOutputFile needs to be called in the main thread");
    
    [_private setOutputFile:outputFile];
}

- (void)setDefaultContentType:(NSString *)defaultContentType
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.setDefaultContentType needs to be called in the main thread");
    
    [_private setDefaultContentType:defaultContentType];
}

- (NSString*)defaultContentType
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.defaultContentType needs to be called in the main thread");
    
    return [_private defaultContentType];
}

- (NSString*)contentType
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.contentType needs to be called in the main thread");
    
    return [_private contentType];
}

- (NSString*)suggestedFileExtension
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.suggestedFileExtension needs to be called in the main thread");
    
    return [_private suggestedFileExtension];
}

- (UInt64)defaultContentLength
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.defaultContentLength needs to be called in the main thread");
    
    return [_private defaultContentLength];
}

- (UInt64)contentLength
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.contentLength needs to be called in the main thread");
    
    return [_private contentLength];
}

- (UInt64)audioDataByteCount
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.audioDataByteCount needs to be called in the main thread");
    
    return [_private audioDataByteCount];
}

- (void)preload
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.preload needs to be called in the main thread");
    
    [_private preload];
}

- (void)play
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.play needs to be called in the main thread");
    
    [_private play];   
}

- (void)playFromURL:(NSURL*)url
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.playFromURL needs to be called in the main thread");
    
    [_private playFromURL:url];
}

- (void)playFromOffset:(FSSeekByteOffset)offset
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.playFromOffset needs to be called in the main thread");
    
    [_private playFromOffset:offset];
}

- (void)stop
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.stop needs to be called in the main thread");
    
    [_private stop];
}

- (void)pause
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.pause needs to be called in the main thread");
    
    [_private pause];
}

- (void)rewind:(unsigned int)seconds
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.rewind needs to be called in the main thread");
    
    [_private rewind:seconds];
}

- (void)seekToPosition:(FSStreamPosition)position
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.seekToPosition needs to be called in the main thread");
    
    if (!(position.position > 0)) {
        // To retain compatibility with older implementations,
        // fallback to using less accurate position.minute and position.second, if needed
        const float seekTime = position.minute * 60 + position.second;
        
        position.position = seekTime / [_private durationInSeconds];
    }
    
    [_private seekToOffset:position.position];
}

- (void)setPlayRate:(float)playRate
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.setPlayRate needs to be called in the main thread");
    
    [_private setPlayRate:playRate];
}

- (BOOL)isPlaying
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.isPlaying needs to be called in the main thread");
    
    return [_private isPlaying];
}

- (void)expungeCache
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.expungeCache needs to be called in the main thread");
    
    [_private expungeCache];
}

- (NSUInteger)retryCount
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.retryCount needs to be called in the main thread");
    
    return _private.retryCount;
}

- (FSStreamStatistics *)statistics
{
    return _private.statistics;
}

- (FSLevelMeterState)levels
{
    return _private.levels;
}

- (FSStreamPosition)currentTimePlayed
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.currentTimePlayed needs to be called in the main thread");
    
    FSStreamPosition pos;
    pos.position = 0;
    pos.playbackTimeInSeconds = [_private playbackPosition].timePlayed;
    pos.minute = 0;
    pos.second = 0;
    
    const float durationInSeconds = [_private durationInSeconds];
    
    if (durationInSeconds > 0) {
        pos.position = pos.playbackTimeInSeconds / [_private durationInSeconds];
    }
    
    // Extract the minutes and seconds for convenience
    if (pos.playbackTimeInSeconds > 0) {
        unsigned u = pos.playbackTimeInSeconds;
        unsigned s,m;
    
        s = u % 60;
        u /= 60;
        m = u;
    
        pos.minute = m;
        pos.second = s;
    }

    return pos;
}

- (FSStreamPosition)duration
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.duration needs to be called in the main thread");
    
    FSStreamPosition pos;
    pos.minute = 0;
    pos.second = 0;
    pos.playbackTimeInSeconds = 0;
    pos.position              = 0;
    
    const float durationInSeconds = [_private durationInSeconds];
    
    if (durationInSeconds > 0) {
        unsigned u = durationInSeconds;
    
        unsigned s,m;
    
        s = u % 60;
        u /= 60;
        m = u;
        
        pos.minute = m;
        pos.second = s;
    }

    pos.playbackTimeInSeconds = durationInSeconds;

    return pos;
}

- (FSSeekByteOffset)currentSeekByteOffset
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.currentSeekByteOffset needs to be called in the main thread");
    
    return _private.currentSeekByteOffset;
}

- (float)bitRate
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.bitRate needs to be called in the main thread");
    
    return _private.bitRate;
}

- (BOOL)continuous
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.continuous needs to be called in the main thread");
    
    return !([_private durationInSeconds] > 0);
}

- (BOOL)cached
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.cached needs to be called in the main thread");
    
    return _private.cached;
}

- (size_t)prebufferedByteCount
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.prebufferedByteCount needs to be called in the main thread");
    
    return _private.prebufferedByteCount;
}

- (float)volume
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.volume needs to be called in the main thread");
    
    return [_private currentVolume];
}

- (unsigned long long)totalCachedObjectsSize
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.totalCachedObjectsSize needs to be called in the main thread");
    
    return [_private totalCachedObjectsSize];
}

- (void)setVolume:(float)volume
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.setVolume needs to be called in the main thread");
    
    [_private setVolume:volume];
}

- (void (^)())onCompletion
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.onCompletion needs to be called in the main thread");
    
    return _private.onCompletion;
}

- (void)setOnCompletion:(void (^)())onCompletion
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.setOnCompletion needs to be called in the main thread");
    
    _private.onCompletion = onCompletion;
}

- (void (^)(FSAudioStreamState state))onStateChange
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.onStateChange needs to be called in the main thread");
    
    return _private.onStateChange;
}

- (void (^)(NSDictionary *metaData))onMetaDataAvailable
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.onMetaDataAvailable needs to be called in the main thread");
    
    return _private.onMetaDataAvailable;
}

- (void (^)(FSAudioStreamError error, NSString *errorDescription))onFailure
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.onFailure needs to be called in the main thread");
    
    return _private.onFailure;
}

- (void)setOnStateChange:(void (^)(FSAudioStreamState))onStateChange
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.setOnStateChange needs to be called in the main thread");
    
    _private.onStateChange = onStateChange;
}

- (void)setOnMetaDataAvailable:(void (^)(NSDictionary *))onMetaDataAvailable
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.setOnMetaDataAvailable needs to be called in the main thread");
    
    _private.onMetaDataAvailable = onMetaDataAvailable;
}

- (void)setOnFailure:(void (^)(FSAudioStreamError error, NSString *errorDescription))onFailure
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.setOnFailure needs to be called in the main thread");
    
    _private.onFailure = onFailure;
}

- (FSStreamConfiguration *)configuration
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.configuration needs to be called in the main thread");
    
    return _private.configuration;
}

- (void)setDelegate:(id<FSPCMAudioStreamDelegate>)delegate
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.setDelegate needs to be called in the main thread");
    
    _private.delegate = delegate;
}

- (id<FSPCMAudioStreamDelegate>)delegate
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.delegate needs to be called in the main thread");
    
    return _private.delegate;
}

-(NSString *)description
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.description needs to be called in the main thread");
    
    return [_private description];
}

-(NSUInteger)maxRetryCount
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.maxRetryCount needs to be called in the main thread");
    
    return [_private maxRetryCount];
}

-(void)setMaxRetryCount:(NSUInteger)maxRetryCount
{
    NSAssert([NSThread isMainThread], @"FSAudioStream.setMaxRetryCount needs to be called in the main thread");
    
    [_private setMaxRetryCount:maxRetryCount];
}

@end

/*
 * ===============================================================
 * AudioStreamStateObserver: listen to the state from the audio stream.
 * ===============================================================
 */

void AudioStreamStateObserver::audioStreamErrorOccurred(int errorCode, CFStringRef errorDescription)
{
    FSAudioStreamError error = kFsAudioStreamErrorNone;
    
    NSString *errorForObjC = @"";
    
    if (errorDescription) {
        errorForObjC = CFBridgingRelease(CFStringCreateCopy(kCFAllocatorDefault, errorDescription));
    }
    
    switch (errorCode) {
        case kFsAudioStreamErrorOpen:
            error = kFsAudioStreamErrorOpen;
            
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
            NSLog(@"FSAudioStream: Error opening the stream: %@ %@", errorForObjC, priv);
#endif
            
            break;
        case kFsAudioStreamErrorStreamParse:
            error = kFsAudioStreamErrorStreamParse;
            
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
            NSLog(@"FSAudioStream: Error parsing the stream: %@ %@", errorForObjC, priv);
#endif
            
            break;
        case kFsAudioStreamErrorNetwork:
            error = kFsAudioStreamErrorNetwork;
        
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
            NSLog(@"FSAudioStream: Network error: %@ %@", errorForObjC, priv);
#endif
            
            break;
        case kFsAudioStreamErrorUnsupportedFormat:
            error = kFsAudioStreamErrorUnsupportedFormat;
    
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
            NSLog(@"FSAudioStream: Unsupported format error: %@ %@", errorForObjC, priv);
#endif
            
            break;
            
        case kFsAudioStreamErrorStreamBouncing:
            error = kFsAudioStreamErrorStreamBouncing;
            
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
            NSLog(@"FSAudioStream: Stream bounced: %@ %@", errorForObjC, priv);
#endif
            
            break;
            
        case kFsAudioStreamErrorTerminated:
            error = kFsAudioStreamErrorTerminated;
            
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
            NSLog(@"FSAudioStream: Stream terminated: %@ %@", errorForObjC, priv);
#endif
            break;
            
        default:
            break;
    }
    
    if (priv.onFailure) {
        priv.onFailure(error, errorForObjC);
    }
    
    NSDictionary *userInfo = @{FSAudioStreamNotificationKey_Error: @(errorCode),
                            FSAudioStreamNotificationKey_ErrorDescription: errorForObjC,
                              FSAudioStreamNotificationKey_Stream: [NSValue valueWithPointer:source]};
    NSNotification *notification = [NSNotification notificationWithName:FSAudioStreamErrorNotification object:priv.stream userInfo:userInfo];
    
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
    if (error == kFsAudioStreamErrorNetwork ||
        error == kFsAudioStreamErrorUnsupportedFormat ||
        error == kFsAudioStreamErrorOpen ||
        error == kFsAudioStreamErrorTerminated) {
        
        if (!source->isPreloading()) {
            [priv attemptRestart];
        }
    }
}
    
void AudioStreamStateObserver::audioStreamStateChanged(astreamer::Audio_Stream::State state)
{
    SEL notificationHandler;
    
    switch (state) {
        case astreamer::Audio_Stream::STOPPED:
            notificationHandler = @selector(notifyPlaybackStopped);
            break;
        case astreamer::Audio_Stream::BUFFERING:
            notificationHandler = @selector(notifyPlaybackBuffering);
            break;
        case astreamer::Audio_Stream::PLAYING:
            [priv endBackgroundTask];
            
            notificationHandler = @selector(notifyPlaybackPlaying);
            break;
        case astreamer::Audio_Stream::PAUSED:
            notificationHandler = @selector(notifyPlaybackPaused);
            break;
        case astreamer::Audio_Stream::SEEKING:
            notificationHandler = @selector(notifyPlaybackSeeking);
            break;
        case astreamer::Audio_Stream::END_OF_FILE:
            notificationHandler = @selector(notifyPlaybackEndOfFile);
            break;
        case astreamer::Audio_Stream::FAILED:
            [priv endBackgroundTask];
            
            notificationHandler = @selector(notifyPlaybackFailed);
            break;
        case astreamer::Audio_Stream::PLAYBACK_COMPLETED:
            notificationHandler = @selector(notifyPlaybackCompletion);
            break;
        default:
            // Unknown state
            notificationHandler = @selector(notifyPlaybackUnknownState);
            break;
    }
    
    // Detach from the player so that the event loop can complete its cycle.
    // This ensures that the stream gets closed, if needs to be.
    [NSTimer scheduledTimerWithTimeInterval:0
                                     target:priv
                                   selector:notificationHandler
                                   userInfo:nil
                                    repeats:NO];
}
    
void AudioStreamStateObserver::audioStreamMetaDataAvailable(std::map<CFStringRef,CFStringRef> metaData)
{
    NSMutableDictionary *metaDataDictionary = [[NSMutableDictionary alloc] init];
    
    for (std::map<CFStringRef,CFStringRef>::iterator iter = metaData.begin(); iter != metaData.end(); ++iter) {
        CFStringRef key = iter->first;
        CFStringRef value = iter->second;
        
        metaDataDictionary[CFBridgingRelease(key)] = CFBridgingRelease(value);
    }
    
    if (priv.onMetaDataAvailable) {
        priv.onMetaDataAvailable(metaDataDictionary);
    }
    
    NSDictionary *userInfo = @{FSAudioStreamNotificationKey_MetaData: metaDataDictionary,
                              FSAudioStreamNotificationKey_Stream: [NSValue valueWithPointer:source]};
    NSNotification *notification = [NSNotification notificationWithName:FSAudioStreamMetaDataNotification object:priv.stream userInfo:userInfo];
    
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

void AudioStreamStateObserver::samplesAvailable(AudioBufferList *samples, UInt32 frames, AudioStreamPacketDescription description)
{
    if ([priv.delegate respondsToSelector:@selector(audioStream:samplesAvailable:frames:description:)]) {
        [priv.delegate audioStream:priv.stream samplesAvailable:samples frames:frames description:description];
    }
}

void AudioStreamStateObserver::bitrateAvailable()
{
    [priv bitrateAvailable];
}
