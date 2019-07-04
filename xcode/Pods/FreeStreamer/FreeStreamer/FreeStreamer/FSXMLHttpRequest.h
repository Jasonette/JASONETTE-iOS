/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#import <Foundation/Foundation.h>

typedef struct _xmlDoc xmlDoc;
typedef xmlDoc *xmlDocPtr;

typedef struct _xmlNode xmlNode;
typedef xmlNode *xmlNodePtr;

/**
 * XML HTTP request error status.
 */
typedef NS_ENUM(NSInteger, FSXMLHttpRequestError) {
    /**
     * No error.
     */
    FSXMLHttpRequestError_NoError = 0,
    /**
     * Connection failed.
     */
    FSXMLHttpRequestError_Connection_Failed,
    /**
     * Invalid HTTP status.
     */
    FSXMLHttpRequestError_Invalid_Http_Status,
    /**
     * XML parser failed.
     */
    FSXMLHttpRequestError_XML_Parser_Failed
};

/**
 * FSXMLHttpRequest is a class for retrieving data in the XML
 * format over a HTTP or HTTPS connection. It provides
 * the necessary foundation for parsing the retrieved XML data.
 * This class is not meant to be used directly but subclassed
 * to a specific requests.
 *
 * The usage pattern is the following:
 *
 * 1. Specify the URL with the url property.
 * 2. Define the onCompletion and onFailure handlers.
 * 3. Call the start method.
 */
@interface FSXMLHttpRequest : NSObject {
    NSURLSessionTask *_task;
    xmlDocPtr _xmlDocument;
    NSDateFormatter *_dateFormatter;
}

/**
 * The URL of the request.
 */
@property (nonatomic,copy) NSURL *url;
/**
 * Called upon completion of the request.
 */
@property (copy) void (^onCompletion)();
/**
 * Called upon a failure.
 */
@property (copy) void (^onFailure)();
/**
 * If the request fails, contains the latest error status.
 */
@property (readonly) FSXMLHttpRequestError lastError;

/**
 * Starts the request.
 */
- (void)start;
/**
 * Cancels the request.
 */
- (void)cancel;

/**
 * Performs an XPath query on the parsed XML data.
 * Yields a parseXMLNode method call, which must be
 * defined in the subclasses.
 *
 * @param query The XPath query to be performed.
 */
- (NSArray *)performXPathQuery:(NSString *)query;
/**
 * Retrieves content for the given XML node.
 *
 * @param node The node for content retreval.
 */
- (NSString *)contentForNode:(xmlNodePtr)node;
/**
 * Retrieves content for the given XML node attribute.
 *
 * @param node The node for content retrieval.
 * @param attr The attribute from which the content is retrieved.
 */
- (NSString *)contentForNodeAttribute:(xmlNodePtr)node attribute:(const char *)attr;
/**
 * Retrieves date from the given XML node.
 *
 * @param node The node for retrieving the date.
 */
- (NSDate *)dateFromNode:(xmlNodePtr)node;

@end