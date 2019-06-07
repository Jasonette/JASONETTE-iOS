/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#import "FSXMLHttpRequest.h"

/**
 * Use this request for retrieving the contents for a podcast RSS feed.
 * Upon request completion, the resulting playlist items are
 * in the playlistItems property.
 *
 * See the FSXMLHttpRequest class how to form a request to retrieve
 * the RSS feed.
 */
@interface FSParseRssPodcastFeedRequest : FSXMLHttpRequest {
    NSMutableArray *_playlistItems;
}

/**
 * The playlist items stored in the FSPlaylistItem class.
 */
@property (readonly) NSMutableArray *playlistItems;

@end