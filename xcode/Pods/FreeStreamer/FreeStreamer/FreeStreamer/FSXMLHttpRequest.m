/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#import "FSXMLHttpRequest.h"

#import <libxml/parser.h>
#import <libxml/xpath.h>

#define DATE_COMPONENTS (NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit |  NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit)
#define CURRENT_CALENDAR [NSCalendar currentCalendar]

@interface FSXMLHttpRequest (PrivateMethods)
- (const char *)detectEncoding;
- (void)parseResponseData;
- (void)parseXMLNode:(xmlNodePtr)node xPathQuery:(NSString *)xPathQuery;

@end

@implementation FSXMLHttpRequest

- (id)init
{
    self = [super init];
    if (self) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return self;
}

- (void)start
{
    
    if (_task) {
        return;
    }
    
    _lastError = FSXMLHttpRequestError_NoError;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:10.0];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    __weak FSXMLHttpRequest *weakSelf = self;

    @synchronized (self) {
        _task = [session dataTaskWithRequest:request
                           completionHandler:
                 ^(NSData *data, NSURLResponse *response, NSError *error) {
                     FSXMLHttpRequest *strongSelf = weakSelf;
                     
                     NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                     if(error) {
                         strongSelf->_lastError = FSXMLHttpRequestError_Connection_Failed;
                         
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
                         NSLog(@"FSXMLHttpRequest: Request failed for URL: %@, error %@", strongSelf.url, [error localizedDescription]);
#endif
                         dispatch_async(dispatch_get_main_queue(), ^(){
                             strongSelf.onFailure();
                         });
                     } else {
                         if (httpResponse.statusCode != 200) {
                             strongSelf->_lastError = FSXMLHttpRequestError_Invalid_Http_Status;
                             
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
                             NSLog(@"FSXMLHttpRequest: Unable to receive content for URL: %@", strongSelf.url);
#endif
                             dispatch_async(dispatch_get_main_queue(), ^(){
                                 strongSelf.onFailure();
                             });
                             return;
                         }
                         
                         const char *encoding = [self detectEncoding:data];
                         
                         strongSelf->_xmlDocument = xmlReadMemory([data bytes],
                                                      (int)[data length],
                                                      "",
                                                      encoding,
                                                      0);
                         
                         if (!strongSelf->_xmlDocument) {
                             strongSelf->_lastError = FSXMLHttpRequestError_XML_Parser_Failed;
                             
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
                             NSLog(@"FSXMLHttpRequest: Unable to parse the content for URL: %@", strongSelf.url);
#endif
                             
                             dispatch_async(dispatch_get_main_queue(), ^(){
                                 strongSelf.onFailure();
                             });
                             return;
                         }
                         
                         [strongSelf parseResponseData];
                         
                         xmlFreeDoc(strongSelf->_xmlDocument), strongSelf->_xmlDocument = nil;
                         
                         dispatch_async(dispatch_get_main_queue(), ^(){
                             strongSelf.onCompletion();
                         });
                     }
                 }];
    }
    [_task resume];
    
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
 * XML handling
 * =======================================
 */

- (NSArray *)performXPathQuery:(NSString *)query
{
    NSMutableArray *resultNodes = [NSMutableArray array];
    xmlXPathContextPtr xpathCtx = NULL;
    xmlXPathObjectPtr xpathObj = NULL;
    
    xpathCtx = xmlXPathNewContext(_xmlDocument);
    if (xpathCtx == NULL) {
        goto cleanup;
    }
    
    xpathObj = xmlXPathEvalExpression((xmlChar *)[query cStringUsingEncoding:NSUTF8StringEncoding], xpathCtx);
    if (xpathObj == NULL) {
        goto cleanup;
    }
    
    xmlNodeSetPtr nodes = xpathObj->nodesetval;
    if (!nodes) {
        goto cleanup;
    }
    
    for (size_t i = 0; i < nodes->nodeNr; i++) {
        [self parseXMLNode:nodes->nodeTab[i] xPathQuery:query];
    }
    
cleanup:
    if (xpathObj) {
        xmlXPathFreeObject(xpathObj);
    }
    if (xpathCtx) {
        xmlXPathFreeContext(xpathCtx);
    }
    return resultNodes;
}

- (NSString *)contentForNode:(xmlNodePtr)node
{
    NSString *stringWithContent;
    if (!node) {
        stringWithContent = [[NSString alloc] init];
    } else {
        xmlChar *content = xmlNodeGetContent(node);
        if (!content) {
            return stringWithContent;
        }
        stringWithContent = @((const char *)content);
        xmlFree(content);
    }
    return stringWithContent;
}

- (NSString *)contentForNodeAttribute:(xmlNodePtr)node attribute:(const char *)attr
{
    NSString *stringWithContent;
    if (!node) {
        stringWithContent = [[NSString alloc] init];
    } else {
        xmlChar *content = xmlGetProp(node, (const xmlChar *)attr);
        if (!content) {
            return stringWithContent;
        }
        stringWithContent = @((const char *)content);
        xmlFree(content);
    }
    return stringWithContent;
}

/*
 * =======================================
 * Helpers
 * =======================================
 */

- (const char *)detectEncoding:(NSData *)receivedData
{
    const char *encoding = 0;
    const char *header = strndup([receivedData bytes], 60);
    
    if (strstr(header, "utf-8") || strstr(header, "UTF-8")) {
        encoding = "UTF-8";
    } else if (strstr(header, "iso-8859-1") || strstr(header, "ISO-8859-1")) {
        encoding = "ISO-8859-1";
    }
    
    free((void *)header);
    return encoding;
}

- (NSDate *)dateFromNode:(xmlNodePtr)node
{
    NSString *dateString = [self contentForNode:node];
    
    /*
     * For some NSDateFormatter date parsing oddities: http://www.openradar.me/9944011
     *
     * Engineering has determined that this issue behaves as intended based on the following information:
     *
     * This is an intentional change in iOS 5. The issue is this: With the short formats as specified by z (=zzz) or v (=vvv),
     * there can be a lot of ambiguity. For example, "ET" for Eastern Time" could apply to different time zones in many different regions.
     * To improve formatting and parsing reliability, the short forms are only used in a locale if the "cu" (commonly used) flag is set
     * for the locale. Otherwise, only the long forms are used (for both formatting and parsing). This is a change in
     * open-source CLDR 2.0 / ICU 4.8, which is the basis for the ICU in iOS 5, which in turn is the basis of NSDateFormatter behavior.
     *
     * For the "en" locale (= "en_US"), the cu flag is set for metazones such as Alaska, America_Central, America_Eastern, America_Mountain,
     * America_Pacific, Atlantic, Hawaii_Aleutian, and GMT. It is not set for Europe_Central.
     *
     * However, for the "en_GB" locale, the cu flag is set for Europe_Central.
     *
     * So, a formatter set for short timezone style "z" or "zzz" and locale "en" or "en_US" will not parse "CEST" or "CET", but if the
     * locale is instead set to "en_GB" it will parse those. The "GMT" style will be parsed by all.
     *
     * If the formatter is set for the long timezone style "zzzz", and the locale is any of "en", "en_US", or "en_GB", then any of the
     * following will be parsed, because they are unambiguous:
     *
     * "Pacific Daylight Time" "Central European Summer Time" "Central European Time"
     *
     */
    
    return [_dateFormatter dateFromString:dateString];
}

@end