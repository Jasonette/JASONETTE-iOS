/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#import <libxml/parser.h>
#import <libxml/xpath.h>

#import "FSParseRssPodcastFeedRequest.h"
#import "FSPlaylistItem.h"

static NSString *const kXPathQueryItems = @"/rss/channel/item";

@interface FSParseRssPodcastFeedRequest ()
- (NSURL *)parseLocalFileUrl:(NSString *)fileUrl;
- (void)parseItems:(xmlNodePtr)node;
@end

@implementation FSParseRssPodcastFeedRequest

- (NSURL *)parseLocalFileUrl:(NSString *)fileUrl
{
    // Resolve the local bundle URL
    NSString *path = [fileUrl substringFromIndex:7];
    
    NSRange range = [path rangeOfString:@"." options:NSBackwardsSearch];
    
    NSString *fileName = [path substringWithRange:NSMakeRange(0, range.location)];
    NSString *suffix = [path substringWithRange:NSMakeRange(range.location + 1, [path length] - [fileName length] - 1)];
    
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:fileName ofType:suffix]];
}

- (void)parseItems:(xmlNodePtr)node
{
    FSPlaylistItem *item = [[FSPlaylistItem alloc] init];
    
    for (xmlNodePtr n = node->children; n != NULL; n = n->next) {
        NSString *nodeName = @((const char *)n->name);
        if ([nodeName isEqualToString:@"title"]) {
            item.title = [self contentForNode:n];
        } else if ([nodeName isEqualToString:@"enclosure"]) {
            NSString *url = [self contentForNodeAttribute:n attribute:"url"];
            
            if ([url hasPrefix:@"file://"]) {
                item.url = [self parseLocalFileUrl:url];
            } else {
                item.url = [NSURL URLWithString:url];
            }
        } else if ([nodeName isEqualToString:@"link"]) {
            NSString *url = [self contentForNode:n];
            
            if ([url hasPrefix:@"file://"]) {
                item.originatingUrl = [self parseLocalFileUrl:url];
            } else {
                item.originatingUrl = [NSURL URLWithString:url];
            }
        }
    }
    
    if (nil == item.url &&
        nil == item.originatingUrl) {
        // Not a valid item, as there is no URL. Skip.
        return;
    }
    
    [_playlistItems addObject:item];
}

- (void)parseResponseData
{
    if (!_playlistItems) {
        _playlistItems = [[NSMutableArray alloc] init];
    }
    [_playlistItems removeAllObjects];
    
    // RSS feed publication date format:
    // Sun, 22 Jul 2012 17:35:05 GMT
    [_dateFormatter setDateFormat:@"EEE, dd MMMM yyyy HH:mm:ss V"];
    [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
    
    [self performXPathQuery:kXPathQueryItems];
}

- (void)parseXMLNode:(xmlNodePtr)node xPathQuery:(NSString *)xPathQuery
{
    if ([xPathQuery isEqualToString:kXPathQueryItems]) {
        [self parseItems:node];
    }
}

- (NSArray *)playlistItems
{
    return _playlistItems;
}

@end