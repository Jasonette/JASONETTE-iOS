/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#import "FSCheckContentTypeRequest.h"

@interface FSCheckContentTypeRequest ()
- (BOOL)guessContentTypeByUrl:(NSURLResponse *)response;
@end

@implementation FSCheckContentTypeRequest

- (id)init
{
    self = [super init];
    if (self) {
        _format = kFSFileFormatUnknown;
        _playlist = NO;
        _xml = NO;
    }
    return self;
}

- (void)start
{
    if (_task) {
        return;
    }
    
    _format = kFSFileFormatUnknown;
    _playlist = NO;
    _contentType = @"";
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:10.0];
    [request setHTTPMethod:@"HEAD"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    @synchronized (self) {
        _task = [session dataTaskWithRequest:request];
    }
    [_task resume];
    
    if (!_task) {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
        NSLog(@"FSCheckContentTypeRequest: Unable to open connection for URL: %@", _url);
#endif
        
        self.onFailure();
        return;
    }
}

- (void)cancel
{
    if (!_task) {
        return;
    }
    @synchronized (self) {
        [_task cancel];
        _task = nil;
    }
}

/*
 * =======================================
 * Properties
 * =======================================
 */

- (FSFileFormat)format
{
    return _format;
}

- (NSString *)contentType
{
    return _contentType;
}

- (BOOL)playlist
{
    return _playlist;
}

- (BOOL)xml
{
    return _xml;
}

/*
 * =======================================
 * NSURLSessionDelegate
 * =======================================
 */

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    _contentType = response.MIMEType;
    
    _format = kFSFileFormatUnknown;
    _playlist = NO;
    
    NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
    
    if (statusCode >= 200 && statusCode <= 299) {
        // Only use the content type if the response indicated success (2xx)
        
        if ([_contentType isEqualToString:@"audio/mpeg"]) {
            _format = kFSFileFormatMP3;
        } else if ([_contentType isEqualToString:@"audio/x-wav"]) {
            _format = kFSFileFormatWAVE;
        } else if ([_contentType isEqualToString:@"audio/x-aifc"]) {
            _format = kFSFileFormatAIFC;
        } else if ([_contentType isEqualToString:@"audio/x-aiff"]) {
            _format = kFSFileFormatAIFF;
        } else if ([_contentType isEqualToString:@"audio/x-m4a"]) {
            _format = kFSFileFormatM4A;
        } else if ([_contentType isEqualToString:@"audio/mp4"]) {
            _format = kFSFileFormatMPEG4;
        } else if ([_contentType isEqualToString:@"audio/x-caf"]) {
            _format = kFSFileFormatCAF;
        } else if ([_contentType isEqualToString:@"audio/aac"] ||
                   [_contentType isEqualToString:@"audio/aacp"]) {
            _format = kFSFileFormatAAC_ADTS;
        } else if ([_contentType isEqualToString:@"audio/x-mpegurl"] ||
                   [_contentType isEqualToString:@"application/x-mpegurl"]) {
            _format = kFSFileFormatM3UPlaylist;
            _playlist = YES;
        } else if ([_contentType isEqualToString:@"audio/x-scpls"] ||
                   [_contentType isEqualToString:@"application/pls+xml"]) {
            _format = kFSFileFormatPLSPlaylist;
            _playlist = YES;
        } else if ([_contentType isEqualToString:@"text/xml"] ||
                   [_contentType isEqualToString:@"application/xml"]) {
            _format = kFSFileFormatXML;
            _xml = YES;
        } else {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
            NSLog(@"FSCheckContentTypeRequest: Cannot resolve %@, guessing the content type by URL: %@", _contentType, _url);
#endif
            [self guessContentTypeByUrl:response];
        }
    } else {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
        NSLog(@"FSCheckContentTypeRequest: Invalid HTTP status code received %li, guessing the content type by URL: %@", (long)statusCode, _url);
#endif
        [self guessContentTypeByUrl:response];
    }
    
    _task = nil;
    
    self.onCompletion();
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    
    @synchronized (self) {
        _task = nil;
        _format = kFSFileFormatUnknown;
        _playlist = NO;
    }
    
    // Still, try if we could resolve the content type by the URL
    if ([self guessContentTypeByUrl:nil]) {
        self.onCompletion();
    } else {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
        NSLog(@"FSCheckContentTypeRequest: Unable to determine content-type for the URL: %@, error %@", _url, [error localizedDescription]);
#endif
        
        self.onFailure();
    }
}

/*
 * =======================================
 * Private
 * =======================================
 */

- (BOOL)guessContentTypeByUrl:(NSURLResponse *)response
{
    /* The server did not provide meaningful content type;
     last resort: check the file suffix, if there is one */
    
    NSString *absoluteUrl;
    
    if (response) {
        absoluteUrl = [response.URL absoluteString];
    } else {
        absoluteUrl = [_url absoluteString];
    }
    
    if ([absoluteUrl hasSuffix:@".mp3"]) {
        _format = kFSFileFormatMP3;
    } else if ([absoluteUrl hasSuffix:@".mp4"]) {
        _format = kFSFileFormatMPEG4;
    } else if ([absoluteUrl hasSuffix:@".m3u"]) {
        _format = kFSFileFormatM3UPlaylist;
        _playlist = YES;
    } else if ([absoluteUrl hasSuffix:@".pls"]) {
        _format = kFSFileFormatPLSPlaylist;
        _playlist = YES;
    } else if ([absoluteUrl hasSuffix:@".xml"]) {
        _format = kFSFileFormatXML;
        _xml = YES;
    } else {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
        NSLog(@"FSCheckContentTypeRequest: Failed to determine content type from the URL: %@", _url);
#endif
        /*
         * Failed to guess the content type based on the URL.
         */
        return NO;
    }
    
    /*
     * We have determined a content-type.
     */
    return YES;
}

@end
