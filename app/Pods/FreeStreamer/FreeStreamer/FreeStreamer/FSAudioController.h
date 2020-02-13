/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2018 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#import <Foundation/Foundation.h>

#include "FSAudioStream.h"

@class FSCheckContentTypeRequest;
@class FSParsePlaylistRequest;
@class FSParseRssPodcastFeedRequest;
@class FSPlaylistItem;
@protocol FSAudioControllerDelegate;

/**
 * FSAudioController is functionally equivalent to FSAudioStream with
 * one addition: it can be directly fed with a playlist (PLS, M3U) URL
 * or an RSS podcast feed. It determines the content type and forms
 * a playlist for playback. Notice that this generates more traffic and
 * is generally more slower than using an FSAudioStream directly.
 *
 * It is also possible to construct a playlist by yourself by providing
 * the playlist items. In this case see the methods for managing the playlist.
 *
 * If you have a playlist with multiple items, FSAudioController attemps
 * automatically preload the next item in the playlist. This helps to
 * start the next item playback immediately without the need for the
 * user to wait for buffering.
 *
 * Notice that do not attempt to set your own blocks to the audio stream
 * owned by the controller. FSAudioController uses the blocks internally
 * and any user set blocks will be overwritten. Instead use the blocks
 * offered by FSAudioController.
 */
@interface FSAudioController : NSObject {
    NSURL *_url;
    NSMutableArray *_streams;
    
    float _volume;
    
    BOOL _readyToPlay;
    
    FSCheckContentTypeRequest *_checkContentTypeRequest;
    FSParsePlaylistRequest *_parsePlaylistRequest;
    FSParseRssPodcastFeedRequest *_parseRssPodcastFeedRequest;
    
    void (^_onStateChangeBlock)(FSAudioStreamState);
    void (^_onMetaDataAvailableBlock)(NSDictionary*);
    void (^_onFailureBlock)(FSAudioStreamError error, NSString *errorDescription);
}

/**
 * Initializes the audio stream with an URL.
 *
 * @param url The URL from which the stream data is retrieved.
 */
- (id)initWithUrl:(NSURL *)url;

/**
 * Starts playing the stream. Before the playback starts,
 * the URL content type is checked and playlists resolved.
 */
- (void)play;

/**
 * Starts playing the stream from an URL. Before the playback starts,
 * the URL content type is checked and playlists resolved.
 *
 * @param url The URL from which the stream data is retrieved.
 */
- (void)playFromURL:(NSURL *)url;

/**
 * Starts playing the stream from the given playlist. Each item in the array
 * must an FSPlaylistItem.
 *
 * @param playlist The playlist items.
 */
- (void)playFromPlaylist:(NSArray *)playlist;

/**
 * Starts playing the stream from the given playlist. Each item in the array
 * must an FSPlaylistItem. The playback starts from the given index
 * in the playlist.
 *
 * @param playlist The playlist items.
 * @param index The playlist index where to start playback from.
 */
- (void)playFromPlaylist:(NSArray *)playlist itemIndex:(NSUInteger)index;

/**
 * Plays a playlist item at the specified index.
 *
 * @param index The playlist index where to start playback from.
 */
- (void)playItemAtIndex:(NSUInteger)index;

/**
 * Returns the count of playlist items.
 */
- (NSUInteger)countOfItems;

/**
 * Adds an item to the playlist.
 *
 * @param item The playlist item to be added.
 */
- (void)addItem:(FSPlaylistItem *)item;

/**
 * Adds an item to the playlist at a specific position.
 *
 * @param item The playlist item to be added.
 * @param index The location in the playlist to place the new item
 */
- (void)insertItem:(FSPlaylistItem *)item atIndex:(NSInteger)index;

/**
 * Moves an item already in the playlist to a different position in the playlist
 *
 * @param from The original index of the track to move
 * @param to The destination of the the track at the index specified in `from`
 */
- (void)moveItemAtIndex:(NSUInteger)from toIndex:(NSUInteger)to;

/**
 * Replaces a playlist item.
 *
 * @param index The index of the playlist item to be replaced.
 * @param item The playlist item used the replace the existing one.
 */
- (void)replaceItemAtIndex:(NSUInteger)index withItem:(FSPlaylistItem *)item;

/**
 * Removes a playlist item.
 *
 * @param index The index of the playlist item to be removed.
 */
- (void)removeItemAtIndex:(NSUInteger)index;

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
 * Returns the playback status: YES if the stream is playing, NO otherwise.
 */
- (BOOL)isPlaying;

/**
 * Returns if the current multiple-item playlist has next item
 */
- (BOOL)hasNextItem;

/**
 * Returns if the current multiple-item playlist has Previous item
 */
- (BOOL)hasPreviousItem;

/**
 * Play the next item of multiple-item playlist
 */
- (void)playNextItem;

/**
 * Play the previous item of multiple-item playlist
 */
- (void)playPreviousItem;

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
 * The controller URL.
 */
@property (nonatomic,assign) NSURL *url;
/**
 * The the active playing stream, which may change
 * from time to time during the playback. In this way, do not
 * set your own blocks to the stream but use the blocks
 * provides by FSAudioController.
 */
@property (readonly) FSAudioStream *activeStream;
/**
 * The playlist item the controller is currently using.
 */
@property (nonatomic,readonly) FSPlaylistItem *currentPlaylistItem;

/**
 * This property determines if the next playlist item should be loaded
 * automatically. This is YES by default.
 */
@property (nonatomic,assign) BOOL preloadNextPlaylistItemAutomatically;

/**
 * This property determines if the debug output is enabled. Disabled
 * by default
 */
@property (nonatomic,assign) BOOL enableDebugOutput;

/**
 * This property determines if automatic audio session handling is enabled.
 * This is YES by default.
 */
@property (nonatomic,assign) BOOL automaticAudioSessionHandlingEnabled;

/**
 * This property holds the configuration used for the streaming.
 */
@property (nonatomic,strong) FSStreamConfiguration *configuration;

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
 * Delegate.
 */
@property (nonatomic,unsafe_unretained) IBOutlet id<FSAudioControllerDelegate> delegate;

@end

/**
 * To check the preloading status, use this delegate.
 */
@protocol FSAudioControllerDelegate <NSObject>

@optional

/**
 * Called when the controller wants to start preloading an item. Return YES or NO
 * depending if you want this item to be preloaded.
 *
 * @param audioController The audio controller which is doing the preloading.
 * @param stream The stream which is wanted to be preloaded.
 */
- (BOOL)audioController:(FSAudioController *)audioController allowPreloadingForStream:(FSAudioStream *)stream;

/**
 * Called when the controller starts to preload an item.
 *
 * @param audioController The audio controller which is doing the preloading.
 * @param stream The stream which is preloaded.
 */
- (void)audioController:(FSAudioController *)audioController preloadStartedForStream:(FSAudioStream *)stream;
@end
