/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2018 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#import <Foundation/Foundation.h>

/**
 * A playlist item. Each item has a title and url.
 */
@interface FSPlaylistItem : NSObject {
}

/**
 * The title of the playlist item.
 */
@property (nonatomic,copy) NSString *title;
/**
 * The URL of the playlist item.
 */
@property (nonatomic,copy) NSURL *url;
/**
 * The originating URL of the playlist item.
 */
@property (nonatomic,copy) NSURL *originatingUrl;

/**
 * The number of bytes of audio data. Notice that this may differ
 * from the number of bytes the server returns for the content length!
 * For instance audio file meta data is excluded from the count.
 * Effectively you can use this property for seeking calculations.
 *
 * The property is only available for non-continuous streams which
 * have been in the "playing" state.
 */
@property (nonatomic,assign) UInt64 audioDataByteCount;

@end
