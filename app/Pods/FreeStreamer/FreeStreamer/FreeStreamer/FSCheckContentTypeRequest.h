/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2018 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#import <Foundation/Foundation.h>

/**
 * Content type format.
 */
typedef NS_ENUM(NSInteger, FSFileFormat) {
    /**
     * Unknown format.
     */
    kFSFileFormatUnknown = 0,
    
    /**
     * M3U playlist.
     */
    kFSFileFormatM3UPlaylist,
    /**
     * PLS playlist.
     */
    kFSFileFormatPLSPlaylist,
    
    /**
     * XML file.
     */
    kFSFileFormatXML,
    
    /**
     * MP3 file.
     */
    kFSFileFormatMP3,
    /**
     * WAVE file.
     */
    kFSFileFormatWAVE,
    /**
     * AIFC file.
     */
    kFSFileFormatAIFC,
    /**
     * AIFF file.
     */
    kFSFileFormatAIFF,
    /**
     * M4A file.
     */
    kFSFileFormatM4A,
    /**
     * MPEG4 file.
     */
    kFSFileFormatMPEG4,
    /**
     * CAF file.
     */
    kFSFileFormatCAF,
    /**
     * AAC_ADTS file.
     */
    kFSFileFormatAAC_ADTS,
    
    /**
     * Total number of formats.
     */
    kFSFileFormatCount
};

/**
 * FSCheckContentTypeRequest is a class for checking the content type
 * of a URL. It makes an HTTP HEAD request and parses the header information
 * from the server. The resulting format is stored in the format property.
 *
 * To use the class, define the URL for checking the content type using
 * the url property. Then, define the onCompletion and onFailure handlers.
 * To start the request, use the start method.
 */
@interface FSCheckContentTypeRequest : NSObject <NSURLSessionDelegate> {
    NSURLSessionTask *_task;
    FSFileFormat _format;
    NSString *_contentType;
    BOOL _playlist;
    BOOL _xml;
}

/**
 * The URL of this request.
 */
@property (nonatomic,copy) NSURL *url;
/**
 * Called when the content type determination is completed.
 */
@property (copy) void (^onCompletion)(void);
/**
 * Called if the content type determination failed.
 */
@property (copy) void (^onFailure)(void);
/**
 * Contains the format of the URL upon completion of the request.
 */
@property (nonatomic,readonly) FSFileFormat format;
/**
 * Containts the content type of the URL upon completion of the request.
 */
@property (nonatomic,readonly) NSString *contentType;
/**
 * The property is true if the URL contains a playlist.
 */
@property (nonatomic,readonly) BOOL playlist;
/**
 * The property is true if the URL contains XML data.
 */
@property (nonatomic,readonly) BOOL xml;

/**
 * Starts the request.
 */
- (void)start;
/**
 * Cancels the request.
 */
- (void)cancel;

@end
