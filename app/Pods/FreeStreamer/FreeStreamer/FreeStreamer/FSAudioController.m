/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2018 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#import "FSAudioController.h"
#import "FSPlaylistItem.h"
#import "FSCheckContentTypeRequest.h"
#import "FSParsePlaylistRequest.h"
#import "FSParseRssPodcastFeedRequest.h"

#import <AVFoundation/AVFoundation.h>

/**
 * Private interface for FSAudioController.
 */
@interface FSAudioController ()
- (void)notifyRetrievingURL;

@property (readonly) FSAudioStream *audioStream;
@property (readonly) FSCheckContentTypeRequest *checkContentTypeRequest;
@property (readonly) FSParsePlaylistRequest *parsePlaylistRequest;
@property (readonly) FSParseRssPodcastFeedRequest *parseRssPodcastFeedRequest;
@property (nonatomic,assign) BOOL readyToPlay;
@property (nonatomic,assign) NSUInteger currentPlaylistItemIndex;
@property (nonatomic,strong) NSMutableArray *playlistItems;
@property (nonatomic,strong) NSMutableArray *streams;
@property (nonatomic,assign) BOOL needToSetVolume;
@property (nonatomic,assign) BOOL songSwitchInProgress;
@property (nonatomic,assign) float outputVolume;

- (void)audioStreamStateDidChange:(NSNotification *)notification;
- (void)deactivateInactivateStreams:(NSUInteger)currentActiveStream;
- (void)setAudioSessionActive:(BOOL)active;

@end

/**
 * Acts as a proxy object for FSAudioStream. Lazily initializes
 * the stream when it is needed.
 *
 * A call to deactivate releases the stream.
 */
@interface FSAudioStreamProxy : NSObject {
    FSAudioStream *_audioStream;
}

@property (readonly) FSAudioStream *audioStream;
@property (nonatomic,copy) NSURL *url;
@property (nonatomic,weak) FSAudioController *audioController;

- (void)deactivate;

@end

/*
 * =======================================
 * FSAudioStreamProxy implementation.
 * =======================================
 */

@implementation FSAudioStreamProxy

- (id)init
{
    if (self = [super init]) {
    }
    return self;
}

- (id)initWithAudioController:(FSAudioController *)controller
{
    if (self = [self init]) {
        self.audioController = controller;
    }
    return self;
}

- (void)dealloc
{
    if (self.audioController.enableDebugOutput) {
        NSLog(@"[FSAudioController.m:%i] FSAudioStreamProxy.dealloc: %@", __LINE__, self.url);
    }
    
    [self deactivate];
}

- (FSAudioStream *)audioStream
{
    if (!_audioStream) {
        FSStreamConfiguration *conf;
        if (self.audioController.configuration) {
            conf = self.audioController.configuration;
        } else {
            conf = [[FSStreamConfiguration alloc] init];
        }
        
        // Disable audio session handling for the audio stream; audio controller handles it
        conf.automaticAudioSessionHandlingEnabled = NO;
        
        _audioStream = [[FSAudioStream alloc] initWithConfiguration:conf];
        
        if (self.audioController.needToSetVolume) {
            _audioStream.volume = self.audioController.outputVolume;
        }
        
        if (self.url) {
            _audioStream.url = self.url;
        }
    }
    return _audioStream;
}

- (void)deactivate
{
    [_audioStream stop];
    
    _audioStream = nil;
}

@end

/*
 * =======================================
 * FSAudioController implementation
 * =======================================
 */

@implementation FSAudioController

-(id)init
{
    if (self = [super init]) {
        _url = nil;
        _checkContentTypeRequest = nil;
        _parsePlaylistRequest = nil;
        _readyToPlay = NO;
        _playlistItems = [[NSMutableArray alloc] init];
        _streams = [[NSMutableArray alloc] init];
        self.preloadNextPlaylistItemAutomatically = YES;
        self.enableDebugOutput = NO;
        self.automaticAudioSessionHandlingEnabled = YES;
        self.configuration = [[FSStreamConfiguration alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(audioStreamStateDidChange:)
                                                     name:FSAudioStreamStateChangeNotification
                                                   object:nil];
    }
    return self;
}

- (id)initWithUrl:(NSURL *)url
{
    if (self = [self init]) {
        self.url = url;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_checkContentTypeRequest cancel];
    [_parsePlaylistRequest cancel];
    [_parseRssPodcastFeedRequest cancel];
    
    for (FSAudioStreamProxy *proxy in _streams) {
        if (self.enableDebugOutput) {
            NSLog(@"[FSAudioController.m:%i] dealloc. Deactivating stream %@", __LINE__, proxy.url);
        }
        
        [proxy deactivate];
    }
    
    [self setAudioSessionActive:NO];
}

- (void)audioStreamStateDidChange:(NSNotification *)notification
{
    if (notification.object == self) {
        // URL retrieving notification from ourselves, ignore
        return;
    }
    
    if (!(notification.object == self.audioStream)) {
        // This doesn't concern us, return
        return;
    }
    
    NSDictionary *dict = [notification userInfo];
    int state = [[dict valueForKey:FSAudioStreamNotificationKey_State] intValue];
    
    if (state == kFSAudioStreamEndOfFile) {
        if (self.enableDebugOutput) {
            NSLog(@"[FSAudioController.m:%i] EOF reached for %@", __LINE__, self.audioStream.url);
        }
        
        if (!self.preloadNextPlaylistItemAutomatically) {
            // No preloading wanted, skip
            if (self.enableDebugOutput) {
                NSLog(@"[FSAudioController.m:%i] Preloading disabled, return.", __LINE__);
            }
            
            return;
        }
        
        // Reached EOF for this stream, do we have another item waiting in the playlist?
        if ([self hasNextItem]) {
            FSAudioStreamProxy *proxy = [_streams objectAtIndex:self.currentPlaylistItemIndex + 1];
            FSAudioStream *nextStream = proxy.audioStream;
            
            if (self.enableDebugOutput) {
                NSLog(@"[FSAudioController.m:%i] Preloading %@", __LINE__, nextStream.url);
            }
            
            if ([self.delegate respondsToSelector:@selector(audioController:allowPreloadingForStream:)]) {
                if ([self.delegate audioController:self allowPreloadingForStream:nextStream]) {
                    [nextStream preload];
                } else {
                    if (self.enableDebugOutput) {
                        NSLog(@"[FSAudioController.m:%i] Preloading disallowed for stream %@", __LINE__, nextStream.url);
                    }
                }
            } else {
                // Start preloading the next stream; we can load this as there is no override
                [nextStream preload];
            }
            
            if ([self.delegate respondsToSelector:@selector(audioController:preloadStartedForStream:)]) {
                [self.delegate audioController:self preloadStartedForStream:nextStream];
            }
        }
    } else if (state == kFsAudioStreamStopped && !self.songSwitchInProgress) {
        if (self.enableDebugOutput) {
            NSLog(@"Stream %@ stopped. No next playlist items. Deactivating audio session", self.audioStream.url);
        }
        
        [self setAudioSessionActive:NO];
    } else if (state == kFsAudioStreamPlaybackCompleted && [self hasNextItem]) {
        self.currentPlaylistItemIndex = self.currentPlaylistItemIndex + 1;
        self.songSwitchInProgress = YES;
        
        [self play];
    } else if (state == kFsAudioStreamFailed) {
        if (self.enableDebugOutput) {
            NSLog(@"Stream %@ failed. Deactivating audio session", self.audioStream.url);
        }
        
        [self setAudioSessionActive:NO];
    } else if (state == kFsAudioStreamBuffering) {
        if (self.enableDebugOutput) {
            NSLog(@"Stream buffering. Activating audio session");
        }
        
        self.songSwitchInProgress = NO;
        
        if (self.automaticAudioSessionHandlingEnabled) {
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 60000)
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
#endif
        }
        [self setAudioSessionActive:YES];
    } else if (state == kFsAudioStreamPlaying) {
        self.currentPlaylistItem.audioDataByteCount = self.activeStream.audioDataByteCount;
    }
}

- (void)deactivateInactivateStreams:(NSUInteger)currentActiveStream
{
    NSUInteger streamIndex = 0;
    
    for (FSAudioStreamProxy *proxy in _streams) {
        if (streamIndex != currentActiveStream) {
            if (self.enableDebugOutput) {
                NSLog(@"[FSAudioController.m:%i] Deactivating stream %@", __LINE__, proxy.url);
            }
            
            [proxy deactivate];
        }
        streamIndex++;
    }
}

- (void)setAudioSessionActive:(BOOL)active
{
    if (self.automaticAudioSessionHandlingEnabled) {
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 60000)
        [[AVAudioSession sharedInstance] setActive:active withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
#else
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
        [[AVAudioSession sharedInstance] setActive:active error:nil];
#endif
#endif
    }
}

/*
 * =======================================
 * Properties
 * =======================================
 */

- (FSAudioStream *)audioStream
{
    FSAudioStream *stream = nil;
    
    if ([_streams count] == 0) {
        if (self.enableDebugOutput) {
            NSLog(@"[FSAudioController.m:%i] Stream count %lu, creating a proxy object", __LINE__, (unsigned long)[_streams count]);
        }
        
        FSAudioStreamProxy *proxy = [[FSAudioStreamProxy alloc] initWithAudioController:self];
        [_streams addObject:proxy];
    }
    
    FSAudioStreamProxy *proxy = [_streams objectAtIndex:self.currentPlaylistItemIndex];
    
    stream = proxy.audioStream;
    
    return stream;
}

- (FSCheckContentTypeRequest *)checkContentTypeRequest
{
    if (!_checkContentTypeRequest) {
        __weak FSAudioController *weakSelf = self;
        
        _checkContentTypeRequest = [[FSCheckContentTypeRequest alloc] init];
        _checkContentTypeRequest.url = self.url;
        _checkContentTypeRequest.onCompletion = ^() {
            if (weakSelf.checkContentTypeRequest.playlist) {
                // The URL is a playlist; retrieve the contents
                [weakSelf.parsePlaylistRequest start];
            } else if (weakSelf.checkContentTypeRequest.xml) {
                // The URL may be an RSS feed, check the contents
                [weakSelf.parseRssPodcastFeedRequest start];
            } else {
                // Not a playlist; try directly playing the URL
                
                weakSelf.readyToPlay = YES;
                [weakSelf play];
            }
        };
        _checkContentTypeRequest.onFailure = ^() {
            // Failed to check the format; try playing anyway
            
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
            NSLog(@"FSAudioController: Failed to check the format, trying to play anyway, URL: %@", weakSelf.audioStream.url);
#endif
            
            weakSelf.readyToPlay = YES;
            [weakSelf play];
        };
    }
    return _checkContentTypeRequest;
}

- (FSParsePlaylistRequest *)parsePlaylistRequest
{
    if (!_parsePlaylistRequest) {
        __weak FSAudioController *weakSelf = self;
        
        _parsePlaylistRequest = [[FSParsePlaylistRequest alloc] init];
        _parsePlaylistRequest.onCompletion = ^() {
            [weakSelf playFromPlaylist:weakSelf.parsePlaylistRequest.playlistItems];
        };
        _parsePlaylistRequest.onFailure = ^() {
            // Failed to parse the playlist; try playing anyway

#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
            NSLog(@"FSAudioController: Playlist parsing failed, trying to play anyway, URL: %@", weakSelf.audioStream.url);
#endif
            
            weakSelf.readyToPlay = YES;
            [weakSelf play];
        };
    }
    return _parsePlaylistRequest;
}

- (FSParseRssPodcastFeedRequest *)parseRssPodcastFeedRequest
{
    if (!_parseRssPodcastFeedRequest) {
        __weak FSAudioController *weakSelf = self;
        
        _parseRssPodcastFeedRequest = [[FSParseRssPodcastFeedRequest alloc] init];
        _parseRssPodcastFeedRequest.onCompletion = ^() {
            [weakSelf playFromPlaylist:weakSelf.parseRssPodcastFeedRequest.playlistItems];
        };
        _parseRssPodcastFeedRequest.onFailure = ^() {
            // Failed to parse the XML file; try playing anyway
            
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
            NSLog(@"FSAudioController: Failed to parse the RSS feed, trying to play anyway, URL: %@", weakSelf.audioStream.url);
#endif
            
            weakSelf.readyToPlay = YES;
            [weakSelf play];
        };
    }
    return _parseRssPodcastFeedRequest;
}

- (void)notifyRetrievingURL
{
    if (self.onStateChange) {
        self.onStateChange(kFsAudioStreamRetrievingURL);
    }
}

- (BOOL)isPlaying
{
    return [self.audioStream isPlaying];
}

/*
 * =======================================
 * Public interface
 * =======================================
 */

- (void)play
{
    if (!self.readyToPlay) {
        /*
         * Not ready to play; start by checking the content type of the given
         * URL.
         */
        [self.checkContentTypeRequest start];
        
        NSDictionary *userInfo = @{FSAudioStreamNotificationKey_State: @(kFsAudioStreamRetrievingURL)};
        NSNotification *notification = [NSNotification notificationWithName:FSAudioStreamStateChangeNotification object:self userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        
        [NSTimer scheduledTimerWithTimeInterval:0
                                         target:self
                                       selector:@selector(notifyRetrievingURL)
                                       userInfo:nil
                                        repeats:NO];
        
        return;
    }
    
    if ([self.playlistItems count] > 0) {
        if (self.currentPlaylistItem.originatingUrl) {
            self.audioStream.url = self.currentPlaylistItem.originatingUrl;
        } else {
            self.audioStream.url = self.currentPlaylistItem.url;
        }
    } else {
        self.audioStream.url = self.url;
    }
    
    if (self.onStateChange) {
        self.audioStream.onStateChange = self.onStateChange;
    }
    if (self.onMetaDataAvailable) {
        self.audioStream.onMetaDataAvailable = self.onMetaDataAvailable;
    }
    if (self.onFailure) {
        self.audioStream.onFailure = self.onFailure;
    }
    
    FSAudioStream *stream = self.audioStream;
    
    if (self.enableDebugOutput) {
        NSLog(@"Playing %@", stream);
    }
    
    [stream play];
}

- (void)playFromURL:(NSURL*)url
{
    if (!url) {
        return;
    }
    
    [_playlistItems removeAllObjects];
    
    [self stop];
    
    self.url = url;
        
    [self play];
}

- (void)playFromPlaylist:(NSArray *)playlist
{
    [self playFromPlaylist:playlist itemIndex:0];
}

- (void)playFromPlaylist:(NSArray *)playlist itemIndex:(NSUInteger)index
{
    [self stop];
    
    self.playlistItems = [[NSMutableArray alloc] init];
    _streams = [[NSMutableArray alloc] init];
    
    self.currentPlaylistItemIndex = 0;
    
    [self.playlistItems addObjectsFromArray:playlist];
    
    for (FSPlaylistItem *item in playlist) {
        FSAudioStreamProxy *proxy = [[FSAudioStreamProxy alloc] initWithAudioController:self];
        proxy.url = item.url;
        
        if (self.enableDebugOutput) {
            NSLog(@"[FSAudioController.m:%i] playFromPlaylist. Adding stream proxy for %@", __LINE__, proxy.url);
        }
        
        [_streams addObject:proxy];
    }
    
    [self playItemAtIndex:index];
}

- (void)playItemAtIndex:(NSUInteger)index
{
    NSUInteger count = [self countOfItems];
    
    if (count == 0) {
        return;
    }
    
    if (index >= count) {
        return;
    }
    
    [self.audioStream stop];
    
    self.currentPlaylistItemIndex = index;
    
    self.readyToPlay = YES;
    
    [self deactivateInactivateStreams:index];
    
    [self play];
}

- (NSUInteger)countOfItems
{
    return [self.playlistItems count];
}

- (void)addItem:(FSPlaylistItem *)item
{
    if (!item) {
        return;
    }
    
    [self.playlistItems addObject:item];
    
    FSAudioStreamProxy *proxy = [[FSAudioStreamProxy alloc] initWithAudioController:self];
    proxy.url = item.url;
    
    if (self.enableDebugOutput) {
        NSLog(@"[FSAudioController.m:%i] addItem. Adding stream proxy for %@", __LINE__, proxy.url);
    }
    
    [_streams addObject:proxy];
}

- (void)insertItem:(FSPlaylistItem *)item atIndex:(NSInteger)index
{
    if (!item) {
        return;
    }
    
    if (index > self.playlistItems.count) {
        return;
    }
    
    if(self.playlistItems.count == 0 && index == 0) {
        [self addItem:item];
        return;
    }
    
    [self.playlistItems insertObject:item
                             atIndex:index];
    
    FSAudioStreamProxy *proxy = [[FSAudioStreamProxy alloc] initWithAudioController:self];
    proxy.url = item.url;
    
    [_streams insertObject:proxy
                   atIndex:index];

    if(index <= self.currentPlaylistItemIndex) {
        _currentPlaylistItemIndex++;
    }
}

- (void)replaceItemAtIndex:(NSUInteger)index withItem:(FSPlaylistItem *)item
{
    NSUInteger count = [self countOfItems];
    
    if (count == 0) {
        return;
    }
    
    if (index >= count) {
        return;
    }
    
    if (self.currentPlaylistItemIndex == index) {
        // If the item is currently playing, do not allow the replacement
        return;
    }
    
    [self.playlistItems replaceObjectAtIndex:index withObject:item];
    
    FSAudioStreamProxy *proxy = [[FSAudioStreamProxy alloc] initWithAudioController:self];
    proxy.url = item.url;
    
    [_streams replaceObjectAtIndex:index withObject:proxy];
}

- (void)moveItemAtIndex:(NSUInteger)from toIndex:(NSUInteger)to {
    NSUInteger count = [self countOfItems];
    
    if (count == 0) {
        return;
    }
    
    if (from >= count || to >= count) {
        return;
    }
    
    if(from == self.currentPlaylistItemIndex) {
        _currentPlaylistItemIndex = to;
    }
    else if(from < self.currentPlaylistItemIndex && to > self.currentPlaylistItemIndex) {
        _currentPlaylistItemIndex--;
    }
    else if(from > self.currentPlaylistItemIndex && to <= self.currentPlaylistItemIndex) {
        _currentPlaylistItemIndex++;
    }
    
    id object = [self.playlistItems objectAtIndex:from];
    [self.playlistItems removeObjectAtIndex:from];
    [self.playlistItems insertObject:object atIndex:to];
    
    id obj = [_streams objectAtIndex:from];
    [_streams removeObjectAtIndex:from];
    [_streams insertObject:obj atIndex:to];
}

- (void)removeItemAtIndex:(NSUInteger)index
{
    NSUInteger count = [self countOfItems];
    
    if (count == 0) {
        return;
    }
    
    if (index >= count) {
        return;
    }
    
    if (self.currentPlaylistItemIndex == index && self.isPlaying) {
        // If the item is currently playing, do not allow the removal
        return;
    }
    
    FSPlaylistItem *current = self.currentPlaylistItem;
    
    [self.playlistItems removeObjectAtIndex:index];
    
    if (self.enableDebugOutput) {
        FSAudioStreamProxy *proxy = [_streams objectAtIndex:index];
        NSLog(@"[FSAudioController.m:%i] removeItemAtIndex. Removing stream proxy %@", __LINE__, proxy.url);
    }
    
    [_streams removeObjectAtIndex:index];
    
    // Update the current playlist item to be correct after the removal
    NSUInteger itemIndex = 0;
    for (FSPlaylistItem *item in self.playlistItems) {
        if (item == current) {
            self.currentPlaylistItemIndex = itemIndex;
            
            break;
        }
        
        itemIndex++;
    }
}

- (void)stop
{
    if ([_streams count] > 0) {
        // Avoid creating an instance if we don't have it
        [self.audioStream stop];
    }
    
    [_checkContentTypeRequest cancel];
    [_parsePlaylistRequest cancel];
    [_parseRssPodcastFeedRequest cancel];
    
    self.readyToPlay = NO;
}

- (void)pause
{
    [self.audioStream pause];
}

-(BOOL)hasMultiplePlaylistItems
{
    return ([self.playlistItems count] > 1);
}

-(BOOL)hasNextItem
{
    return [self hasMultiplePlaylistItems] && (self.currentPlaylistItemIndex + 1 < [self.playlistItems count]);
}

-(BOOL)hasPreviousItem
{
    return ([self hasMultiplePlaylistItems] && (self.currentPlaylistItemIndex != 0));
}

-(void)playNextItem
{
    if ([self hasNextItem]) {
        if (self.enableDebugOutput) {
            NSLog(@"[FSAudioController.m:%i] playNexItem. Stopping stream %@", __LINE__, self.audioStream.url);
        }
        [self.audioStream stop];
        
        [self deactivateInactivateStreams:self.currentPlaylistItemIndex];
        
        self.currentPlaylistItemIndex = self.currentPlaylistItemIndex + 1;
        
        [self play];
    }
}

-(void)playPreviousItem
{
    if ([self hasPreviousItem]) {
        if (self.enableDebugOutput) {
            NSLog(@"[FSAudioController.m:%i] playPreviousItem. Stopping stream %@", __LINE__, self.audioStream.url);
        }
        [self.audioStream stop];
        
        [self deactivateInactivateStreams:self.currentPlaylistItemIndex];
        
        self.currentPlaylistItemIndex = self.currentPlaylistItemIndex - 1;
        
        [self play];
    }
}

/*
 * =======================================
 * Properties
 * =======================================
 */

- (void)setVolume:(float)volume
{
    self.outputVolume = volume;
    self.needToSetVolume = YES;
    
    if ([_streams count] > 0) {
        self.audioStream.volume = self.outputVolume;
    }
}

- (float)volume
{
    return self.outputVolume;
}

- (void)setUrl:(NSURL *)url
{
    [self stop];
    
    if (url) {
        NSURL *copyOfURL = [url copy];
        _url = copyOfURL;
    
        self.checkContentTypeRequest.url = _url;
        self.parsePlaylistRequest.url = _url;
        self.parseRssPodcastFeedRequest.url = _url;
        
        if ([_url isFileURL]) {
            /*
             * Local file URLs can be directly played
             */
            self.readyToPlay = YES;
        }
    } else {
        _url = nil;
    }
}

- (NSURL* )url
{
    if (!_url) {
        return nil;
    }
    
    NSURL *copyOfURL = [_url copy];
    return copyOfURL;
}

- (FSAudioStream *)activeStream
{
    if ([_streams count] > 0) {
        return self.audioStream;
    }
    return nil;
}

- (FSPlaylistItem *)currentPlaylistItem
{
    if (self.readyToPlay) {
        if ([self.playlistItems count] > 0) {
            FSPlaylistItem *playlistItem = (self.playlistItems)[self.currentPlaylistItemIndex];
            return playlistItem;
        }
    }
    return nil;
}

- (void (^)(FSAudioStreamState state))onStateChange
{
    return _onStateChangeBlock;
}

- (void (^)(NSDictionary *metaData))onMetaDataAvailable
{
    return _onMetaDataAvailableBlock;
}

- (void (^)(FSAudioStreamError error, NSString *errorDescription))onFailure
{
    return _onFailureBlock;
}

- (void)setOnStateChange:(void (^)(FSAudioStreamState))newOnStateValue
{
    _onStateChangeBlock = newOnStateValue;
    
    if ([_streams count] > 0) {
        self.audioStream.onStateChange = _onStateChangeBlock;
    }
}

- (void)setOnMetaDataAvailable:(void (^)(NSDictionary *))newOnMetaDataAvailableValue
{
    _onMetaDataAvailableBlock = newOnMetaDataAvailableValue;
    
    if ([_streams count] > 0) {
        self.audioStream.onMetaDataAvailable = _onMetaDataAvailableBlock;
    }
}

- (void)setOnFailure:(void (^)(FSAudioStreamError error, NSString *errorDescription))newOnFailureValue
{
    _onFailureBlock = newOnFailureValue;
    
    if ([_streams count] > 0) {
        self.audioStream.onFailure = _onFailureBlock;
    }
}

@end
