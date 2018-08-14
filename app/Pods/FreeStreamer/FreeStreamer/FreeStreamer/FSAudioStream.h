/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>

/**
 * The major version of the current release.
 */
#define FREESTREAMER_VERSION_MAJOR          3

/**
 * The minor version of the current release.
 */
#define FREESTREAMER_VERSION_MINOR          5

/**
 * The reversion of the current release
 */
#define FREESTREAMER_VERSION_REVISION       7

/**
 * Follow this notification for the audio stream state changes.
 */
extern NSString* const FSAudioStreamStateChangeNotification;
extern NSString* const FSAudioStreamNotificationKey_State;

/**
 * Follow this notification for the audio stream errors.
 */
extern NSString* const FSAudioStreamErrorNotification;
extern NSString* const FSAudioStreamNotificationKey_Error;

/**
 * Follow this notification for the audio stream metadata.
 */
extern NSString* const FSAudioStreamMetaDataNotification;
extern NSString* const FSAudioStreamNotificationKey_MetaData;

/**
 * The audio stream state.
 */
typedef NS_ENUM(NSInteger, FSAudioStreamState) {
    /**
     * Retrieving URL.
     */
    kFsAudioStreamRetrievingURL,
    /**
     * Stopped.
     */
    kFsAudioStreamStopped,
    /**
     * Buffering.
     */
    kFsAudioStreamBuffering,
    /**
     * Playing.
     */
    kFsAudioStreamPlaying,
    /**
     * Paused.
     */
    kFsAudioStreamPaused,
    /**
     * Seeking.
     */
    kFsAudioStreamSeeking,
    /**
     * The stream has received all the data for a file.
     */
    kFSAudioStreamEndOfFile,
    /**
     * Failed.
     */
    kFsAudioStreamFailed,
    /**
     * Started retrying.
     */
    kFsAudioStreamRetryingStarted,
    /**
     * Retrying succeeded.
     */
    kFsAudioStreamRetryingSucceeded,
    /**
     * Retrying failed.
     */
    kFsAudioStreamRetryingFailed,
    /**
     * Playback completed.
     */
    kFsAudioStreamPlaybackCompleted,
    /**
     * Unknown state.
     */
    kFsAudioStreamUnknownState
};

/**
 * The audio stream errors.
 */
typedef NS_ENUM(NSInteger, FSAudioStreamError) {
    /**
     * No error.
     */
    kFsAudioStreamErrorNone = 0,
    /**
     * Error opening the stream.
     */
    kFsAudioStreamErrorOpen = 1,
    /**
     * Error parsing the stream.
     */
    kFsAudioStreamErrorStreamParse = 2,
    /**
     * Network error.
     */
    kFsAudioStreamErrorNetwork = 3,
    /**
     * Unsupported format.
     */
    kFsAudioStreamErrorUnsupportedFormat = 4,
    /**
     * Stream buffered too often.
     */
    kFsAudioStreamErrorStreamBouncing = 5,
    /**
     * Stream playback was terminated by the operating system.
     */
    kFsAudioStreamErrorTerminated = 6
};

@protocol FSPCMAudioStreamDelegate;
@class FSAudioStreamPrivate;

/**
 * The audio stream playback position.
 */
typedef struct {
    unsigned minute;
    unsigned second;
    
    /**
     * Playback time in seconds.
     */
    float playbackTimeInSeconds;
    
    /**
     * Position within the stream, where 0 is the beginning
     * and 1.0 is the end.
     */
    float position;
} FSStreamPosition;

/**
 * The audio stream seek byte offset.
 */
typedef struct {
    UInt64 start;
    UInt64 end;
    /**
     * Position within the stream, where 0 is the beginning
     * and 1.0 is the end.
     */
    float position;
} FSSeekByteOffset;

/**
 * Audio levels.
 */
typedef struct {
    Float32 averagePower;
    Float32 peakPower;
} FSLevelMeterState;

/**
 * The low-level stream configuration.
 */
@interface FSStreamConfiguration : NSObject {
}

/**
 * The number of buffers.
 */
@property (nonatomic,assign) unsigned bufferCount;
/**
 * The size of each buffer.
 */
@property (nonatomic,assign) unsigned bufferSize;
/**
 * The number of packet descriptions.
 */
@property (nonatomic,assign) unsigned maxPacketDescs;
/**
 * The HTTP connection buffer size.
 */
@property (nonatomic,assign) unsigned httpConnectionBufferSize;
/**
 * The output sample rate.
 */
@property (nonatomic,assign) double   outputSampleRate;
/**
 * The number of output channels.
 */
@property (nonatomic,assign) long     outputNumChannels;
/**
 * The interval within the stream may enter to the buffering state before it fails.
 */
@property (nonatomic,assign) int      bounceInterval;
/**
 * The number of times the stream may enter the buffering state before it fails.
 */
@property (nonatomic,assign) int      maxBounceCount;
/**
 * The stream must start within this seconds before it fails.
 */
@property (nonatomic,assign) int      startupWatchdogPeriod;
/**
 * Allow buffering of this many bytes before the cache is full.
 */
@property (nonatomic,assign) int      maxPrebufferedByteCount;
/**
 * Calculate prebuffer sizes dynamically using the stream bitrate in seconds instead of bytes.
 */
@property (nonatomic,assign) BOOL     usePrebufferSizeCalculationInSeconds;
/**
 * Calculate prebuffer sizes using the packet counts.
 */
@property (nonatomic,assign) BOOL     usePrebufferSizeCalculationInPackets;
/**
 * Require buffering of this many bytes before the playback can start for a continuous stream.
 */
@property (nonatomic,assign) float      requiredPrebufferSizeInSeconds;
/**
 * Require buffering of this many bytes before the playback can start for a continuous stream.
 */
@property (nonatomic,assign) int      requiredInitialPrebufferedByteCountForContinuousStream;
/**
 * Require buffering of this many bytes before the playback can start a non-continuous stream.
 */
@property (nonatomic,assign) int      requiredInitialPrebufferedByteCountForNonContinuousStream;
/**
 * Require buffering of this many packets before the playback can start.
 */
@property (nonatomic,assign) int      requiredInitialPrebufferedPacketCount;
/**
 * The HTTP user agent used for stream operations.
 */
@property (nonatomic,strong) NSString *userAgent;
/**
 * The directory used for caching the streamed files.
 */
@property (nonatomic,strong) NSString *cacheDirectory;
/**
 * The HTTP headers that are appended to the request when the streaming starts. Notice
 * that the headers override any headers previously set by FreeStreamer.
 */
@property (nonatomic,strong) NSDictionary *predefinedHttpHeaderValues;
/**
 * The property determining if caching the streams to the disk is enabled.
 */
@property (nonatomic,assign) BOOL cacheEnabled;
/**
 * The property determining if seeking from the audio packets stored in cache is enabled.
 * The benefit is that seeking is faster in the case the audio packets are already cached in memory.
 */
@property (nonatomic,assign) BOOL seekingFromCacheEnabled;
/**
 * The property determining if FreeStreamer should handle audio session automatically.
 * Leave it on if you don't want to handle the audio session by yourself.
 */
@property (nonatomic,assign) BOOL automaticAudioSessionHandlingEnabled;
/**
 * The property enables time and pitch conversion for the audio queue. Put it on
 * if you want to use the play rate setting.
 */
@property (nonatomic,assign) BOOL enableTimeAndPitchConversion;
/**
 * Requires the content type given by the server to match an audio content type.
 */
@property (nonatomic,assign) BOOL requireStrictContentTypeChecking;
/**
 * The maximum size of the disk cache in bytes.
 */
@property (nonatomic,assign) int maxDiskCacheSize;

@end

/**
 * Statistics on the stream state.
 */
@interface FSStreamStatistics : NSObject {
}

/**
 * Time when the statistics were gathered.
 */
@property (nonatomic,strong) NSDate *snapshotTime;
/**
 * Time in a pretty format.
 */
@property (nonatomic,readonly) NSString *snapshotTimeFormatted;
/**
 * Audio stream packet count.
 */
@property (nonatomic,assign) NSUInteger audioStreamPacketCount;
/**
 * Audio queue used buffers count.
 */
@property (nonatomic,assign) NSUInteger audioQueueUsedBufferCount;
/**
 * Audio stream PCM packet queue count.
 */
@property (nonatomic,assign) NSUInteger audioQueuePCMPacketQueueCount;

@end

NSString*             freeStreamerReleaseVersion();

/**
 * FSAudioStream is a class for streaming audio files from an URL.
 * It must be directly fed with an URL, which contains audio. That is,
 * playlists or other non-audio formats yield an error.
 *
 * To start playback, the stream must be either initialized with an URL
 * or the playback URL can be set with the url property. The playback
 * is started with the play method. It is possible to pause or stop
 * the stream with the respective methods.
 *
 * Non-continuous streams (audio streams with a known duration) can be
 * seeked with the seekToPosition method.
 *
 * Note that FSAudioStream is not designed to be thread-safe! That means
 * that using the streamer from multiple threads without syncronization
 * could cause problems. It is recommended to keep the streamer in the
 * main thread and call the streamer methods only from the main thread
 * (consider using performSelectorOnMainThread: if calls from multiple
 * threads are needed).
 */
@interface FSAudioStream : NSObject {
    FSAudioStreamPrivate *_private;
}

/**
 * Initializes the audio stream with an URL.
 *
 * @param url The URL from which the stream data is retrieved.
 */
- (id)initWithUrl:(NSURL *)url;

/**
 * Initializes the stream with a configuration.
 *
 * @param configuration The stream configuration.
 */
- (id)initWithConfiguration:(FSStreamConfiguration *)configuration;

/**
 * Starts preload the stream. If no preload URL is
 * defined, an error will occur.
 */
- (void)preload;

/**
 * Starts playing the stream. If no playback URL is
 * defined, an error will occur.
 */
- (void)play;

/**
 * Starts playing the stream from the given URL.
 *
 * @param url The URL from which the stream data is retrieved.
 */
- (void)playFromURL:(NSURL*)url;

/**
 * Starts playing the stream from the given offset.
 * The offset can be retrieved from the stream with the
 * currentSeekByteOffset property.
 *
 * @param offset The offset where to start playback from.
 */
- (void)playFromOffset:(FSSeekByteOffset)offset;

/**
 * Stops the stream playback.
 */
- (void)stop;

/**
 * If the stream is playing, the stream playback is paused upon calling pause.
 * Otherwise (the stream is paused), calling pause will continue the playback.
 */
- (void)pause;

/**
 * Rewinds the stream. Only possible for continuous streams.
 *
 * @param seconds Seconds to rewind the stream.
 */
- (void)rewind:(unsigned)seconds;

/**
 * Seeks the stream to a given position. Requires a non-continuous stream
 * (a stream with a known duration).
 *
 * @param position The stream position to seek to.
 */
- (void)seekToPosition:(FSStreamPosition)position;

/**
 * Sets the audio stream playback rate from 0.5 to 2.0.
 * Value 1.0 means the normal playback rate. Values below
 * 1.0 means a slower playback rate than usual and above
 * 1.0 a faster playback rate. Notice that using a faster
 * playback rate than 1.0 may mean that you have to increase
 * the buffer sizes for the stream still to play.
 *
 * The play rate has only effect if the stream is playing.
 *
 * @param playRate The playback rate.
 */
- (void)setPlayRate:(float)playRate;

/**
 * Returns the playback status: YES if the stream is playing, NO otherwise.
 */
- (BOOL)isPlaying;

/**
 * Cleans all cached data from the persistent storage.
 */
- (void)expungeCache;

/**
 * The stream URL.
 */
@property (nonatomic,assign) NSURL *url;
/**
 * Determines if strict content type checking  is required. If the audio stream
 * cannot determine that the stream is actually an audio stream, the stream
 * does not play. Disabling strict content type checking bypasses the
 * stream content type checks and tries to play the stream regardless
 * of the content type information given by the server.
 */
@property (nonatomic,assign) BOOL strictContentTypeChecking;
/**
 * Set an output file to store the stream contents to a file.
 */
@property (nonatomic,assign) NSURL *outputFile;
/**
 * Sets a default content type for the stream. Used if
 * the stream content type is not available.
 */
@property (nonatomic,assign) NSString *defaultContentType;
/**
 * The property has the content type of the stream, for instance audio/mpeg.
 */
@property (nonatomic,readonly) NSString *contentType;
/**
 * The property has the suggested file extension for the stream based on the stream content type.
 */
@property (nonatomic,readonly) NSString *suggestedFileExtension;
/**
 * Sets a default content length for the stream.  Used if
 * the stream content-length is not available.
 */
@property (nonatomic, assign) UInt64 defaultContentLength;
/**
 * The property has the content length of the stream (in bytes). The length is zero if
 * the stream is continuous.
 */
@property (nonatomic,readonly) UInt64 contentLength;
/**
 * This property has the current playback position, if the stream is non-continuous.
 * The current playback position cannot be determined for continuous streams.
 */
@property (nonatomic,readonly) FSStreamPosition currentTimePlayed;
/**
 * This property has the duration of the stream, if the stream is non-continuous.
 * Continuous streams do not have a duration.
 */
@property (nonatomic,readonly) FSStreamPosition duration;
/**
 * This property has the current seek byte offset of the stream, if the stream is non-continuous.
 * Continuous streams do not have a seek byte offset.
 */
@property (nonatomic,readonly) FSSeekByteOffset currentSeekByteOffset;
/**
 * This property has the bit rate of the stream. The bit rate is initially 0,
 * before the stream has processed enough packets to calculate the bit rate.
 */
@property (nonatomic,readonly) float bitRate;
/**
 * The property is true if the stream is continuous (no known duration).
 */
@property (nonatomic,readonly) BOOL continuous;
/**
 * The property is true if the stream has been cached locally.
 */
@property (nonatomic,readonly) BOOL cached;
/**
 * This property has the number of bytes buffered for this stream.
 */
@property (nonatomic,readonly) size_t prebufferedByteCount;
/**
 * This property holds the current playback volume of the stream,
 * from 0.0 to 1.0.
 *
 * Note that the overall volume is still constrained by the volume
 * set by the user! So the actual volume cannot be higher
 * than the volume currently set by the user. For example, if
 * requesting a volume of 0.5, then the volume will be 50%
 * lower than the current playback volume set by the user.
 */
@property (nonatomic,assign) float volume;
/**
 * The current size of the disk cache.
 */
@property (nonatomic,readonly) unsigned long long totalCachedObjectsSize;
/**
 * The property determines the amount of times the stream has tried to retry the playback
 * in case of failure.
 */
@property (nonatomic,readonly) NSUInteger retryCount;
/**
 * Holds the maximum amount of playback retries that will be 
 * performed before entering kFsAudioStreamRetryingFailed state.
 * Default is 3.
 */
@property (nonatomic,assign) NSUInteger maxRetryCount;
/**
 * The property determines the current audio levels.
 */
@property (nonatomic,readonly) FSLevelMeterState levels;
/**
 * This property holds the current statistics for the stream state.
 */
@property (nonatomic,readonly) FSStreamStatistics *statistics;
/**
 * Called upon completion of the stream. Note that for continuous
 * streams this is never called.
 */
@property (copy) void (^onCompletion)();
/**
 * Called upon a state change.
 */
@property (copy) void (^onStateChange)(FSAudioStreamState state);
/**
 * Called upon a meta data is available.
 */
@property (copy) void (^onMetaDataAvailable)(NSDictionary *metadata);
/**
 * Called upon a failure.
 */
@property (copy) void (^onFailure)(FSAudioStreamError error, NSString *errorDescription);
/**
 * The property has the low-level stream configuration.
 */
@property (readonly) FSStreamConfiguration *configuration;
/**
 * Delegate.
 */
@property (nonatomic,unsafe_unretained) IBOutlet id<FSPCMAudioStreamDelegate> delegate;

@end

/**
 * To access the PCM audio data, use this delegate.
 */
@protocol FSPCMAudioStreamDelegate <NSObject>

@optional
/**
 * Called when there are PCM audio samples available. Do not do any blocking operations
 * when you receive the data. Instead, copy the data and process it so that the
 * main event loop doesn't block. Failing to do so may cause glitches to the audio playback.
 *
 * Notice that the delegate callback may occur from other than the main thread so make
 * sure your delegate code is thread safe.
 *
 * @param audioStream The audio stream the samples are from.
 * @param samples The samples as a buffer list.
 * @param frames The number of frames.
 * @param description Description of the data provided.
 */
- (void)audioStream:(FSAudioStream *)audioStream samplesAvailable:(AudioBufferList *)samples frames:(UInt32)frames description: (AudioStreamPacketDescription)description;
@end
