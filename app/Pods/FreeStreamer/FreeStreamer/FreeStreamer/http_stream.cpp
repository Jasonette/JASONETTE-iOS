/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#include "http_stream.h"
#include "audio_queue.h"
#include "id3_parser.h"
#include "stream_configuration.h"

//#define HS_DEBUG 1

#if !defined (HS_DEBUG)
#define HS_TRACE(...) do {} while (0)
#define HS_TRACE_CFSTRING(X) do {} while (0)
#else
#define HS_TRACE(...) printf(__VA_ARGS__)
#define HS_TRACE_CFSTRING(X) HS_TRACE("%s\n", CFStringGetCStringPtr(X, kCFStringEncodingMacRoman))
#endif

/*
 * Comment the following line to disable ID3 tag support:
 */
#define INCLUDE_ID3TAG_SUPPORT 1

namespace astreamer {

CFStringRef HTTP_Stream::httpRequestMethod   = CFSTR("GET");
CFStringRef HTTP_Stream::httpUserAgentHeader = CFSTR("User-Agent");
CFStringRef HTTP_Stream::httpRangeHeader     = CFSTR("Range");
CFStringRef HTTP_Stream::icyMetaDataHeader = CFSTR("Icy-MetaData");
CFStringRef HTTP_Stream::icyMetaDataValue  = CFSTR("1"); /* always request ICY metadata, if available */

    
/* HTTP_Stream: public */
HTTP_Stream::HTTP_Stream() :
    m_readStream(0),
    m_scheduledInRunLoop(false),
    m_readPending(false),
    m_url(0),
    m_httpHeadersParsed(false),
    m_contentType(0),
    m_contentLength(0),
    m_bytesRead(0),
    
    m_icyStream(false),
    m_icyHeaderCR(false),
    m_icyHeadersRead(false),
    m_icyHeadersParsed(false),
    
    m_icyName(0),
    
    m_icyMetaDataInterval(0),
    m_dataByteReadCount(0),
    m_metaDataBytesRemaining(0),
    
    m_httpReadBuffer(0),
    m_icyReadBuffer(0),
    
    m_id3Parser(new ID3_Parser())
{
    m_id3Parser->m_delegate = this;
}

HTTP_Stream::~HTTP_Stream()
{
    close();
    
    for (std::vector<CFStringRef>::iterator h = m_icyHeaderLines.begin(); h != m_icyHeaderLines.end(); ++h) {
        CFRelease(*h);
    }
    
    m_icyHeaderLines.clear();
    
    if (m_contentType) {
        CFRelease(m_contentType), m_contentType = 0;
    }
    
    if (m_icyName) {
        CFRelease(m_icyName), m_icyName = 0;
    }
    
    if (m_httpReadBuffer) {
        delete [] m_httpReadBuffer, m_httpReadBuffer = 0;
    }
    if (m_icyReadBuffer) {
        delete [] m_icyReadBuffer, m_icyReadBuffer = 0;
    }
    if (m_url) {
        CFRelease(m_url), m_url = 0;
    }
    
    delete m_id3Parser, m_id3Parser = 0;
}
    
Input_Stream_Position HTTP_Stream::position()
{
    return m_position;
}
    
CFStringRef HTTP_Stream::contentType()
{
    return m_contentType;
}
    
size_t HTTP_Stream::contentLength()
{
    return m_contentLength;
}
    
bool HTTP_Stream::open()
{
    Input_Stream_Position position;
    position.start = 0;
    position.end = 0;
    
    m_contentLength = 0;
#ifdef INCLUDE_ID3TAG_SUPPORT
    m_id3Parser->reset();
#endif
    
    return open(position);
}

bool HTTP_Stream::open(const Input_Stream_Position& position)
{
    bool success = false;
    CFStreamClientContext CTX = { 0, this, NULL, NULL, NULL };
    
    /* Already opened a read stream, return */
    if (m_readStream) {
        goto out;
    }
    
    /* Reset state */
    m_position = position;
    
    m_readPending = false;
    m_httpHeadersParsed = false;
    
    if (m_contentType) {
        CFRelease(m_contentType), m_contentType = NULL;
    }
    
    m_icyStream = false;
    m_icyHeaderCR = false;
    m_icyHeadersRead = false;
    m_icyHeadersParsed = false;
    
    if (m_icyName) {
        CFRelease(m_icyName), m_icyName = 0;
    }
    
    for (std::vector<CFStringRef>::iterator h = m_icyHeaderLines.begin(); h != m_icyHeaderLines.end(); ++h) {
        CFRelease(*h);
    }
    
    m_icyHeaderLines.clear();
    m_icyMetaDataInterval = 0;
    m_dataByteReadCount = 0;
    m_metaDataBytesRemaining = 0;
    m_bytesRead = 0;
    
    if (!m_url) {
        goto out;
    }
	
    /* Failed to create a stream */
    if (!(m_readStream = createReadStream(m_url))) {
        goto out;
    }
    
    if (!CFReadStreamSetClient(m_readStream, kCFStreamEventHasBytesAvailable |
	                                         kCFStreamEventEndEncountered |
	                                         kCFStreamEventErrorOccurred, readCallBack, &CTX)) {
        CFRelease(m_readStream), m_readStream = 0;
        goto out;
    }
    
    setScheduledInRunLoop(true);
    
    if (!CFReadStreamOpen(m_readStream)) {
        /* Open failed: clean */
        CFReadStreamSetClient(m_readStream, 0, NULL, NULL);
        setScheduledInRunLoop(false);
        if (m_readStream) {
            CFRelease(m_readStream), m_readStream = 0;
        }
        goto out;
    }
    
    success = true;

out:
    return success;
}

void HTTP_Stream::close()
{
    /* The stream has been already closed */
    if (!m_readStream) {
        return;
    }
    
    CFReadStreamSetClient(m_readStream, 0, NULL, NULL);
    setScheduledInRunLoop(false);
    CFReadStreamClose(m_readStream);
    CFRelease(m_readStream), m_readStream = 0;
}
    
void HTTP_Stream::setScheduledInRunLoop(bool scheduledInRunLoop)
{
    /* The stream has not been opened, or it has been already closed */
    if (!m_readStream) {
        return;
    }
    
    /* The state doesn't change */
    if (m_scheduledInRunLoop == scheduledInRunLoop) {
        return;
    }
    
    if (m_scheduledInRunLoop) {
        CFReadStreamUnscheduleFromRunLoop(m_readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    } else {
        if (m_readPending) {
            m_readPending = false;
            
            readCallBack(m_readStream, kCFStreamEventHasBytesAvailable, this);
        }
        
        CFReadStreamScheduleWithRunLoop(m_readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    }
    
    m_scheduledInRunLoop = scheduledInRunLoop;
}
    
void HTTP_Stream::setUrl(CFURLRef url)
{
    if (m_url) {
        CFRelease(m_url);
    }
    if (url) {
        m_url = (CFURLRef)CFRetain(url);
    } else {
        m_url = NULL;
    }
}
    
bool HTTP_Stream::canHandleUrl(CFURLRef url)
{
    if (!url) {
        return false;
    }
    
    CFStringRef scheme = CFURLCopyScheme(url);
    
    if (scheme) {
        if (CFStringCompare(scheme, CFSTR("file"), 0) == kCFCompareEqualTo) {
            CFRelease(scheme);
            
            // The only scheme we claim not to handle are local files.
            return false;
        }
        
        CFRelease(scheme);
    }
    
    return true;
}
    
void HTTP_Stream::id3metaDataAvailable(std::map<CFStringRef,CFStringRef> metaData)
{
    if (m_delegate) {
        m_delegate->streamMetaDataAvailable(metaData);
    }
}
    
void HTTP_Stream::id3tagSizeAvailable(UInt32 tagSize)
{
    if (m_delegate) {
        m_delegate->streamMetaDataByteSizeAvailable(tagSize);
    }
}

/* private */
    
CFReadStreamRef HTTP_Stream::createReadStream(CFURLRef url)
{
    CFReadStreamRef readStream = 0;
    CFHTTPMessageRef request = 0;
    CFDictionaryRef proxySettings = 0;
    
    Stream_Configuration *config = Stream_Configuration::configuration();
    
    if (!(request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, httpRequestMethod, url, kCFHTTPVersion1_1))) {
        goto out;
    }
    
    if (config->userAgent) {
        CFHTTPMessageSetHeaderFieldValue(request, httpUserAgentHeader, config->userAgent);
    }
    
    CFHTTPMessageSetHeaderFieldValue(request, icyMetaDataHeader, icyMetaDataValue);
    
    if (m_position.start > 0 && m_position.end > m_position.start) {
        CFStringRef rangeHeaderValue = CFStringCreateWithFormat(NULL,
                                                                NULL,
                                                                CFSTR("bytes=%llu-%llu"),
                                                                m_position.start,
                                                                m_position.end);
        
        CFHTTPMessageSetHeaderFieldValue(request, httpRangeHeader, rangeHeaderValue);
        CFRelease(rangeHeaderValue);
    }
    
    if (config->predefinedHttpHeaderValues) {
        const CFIndex numKeys = CFDictionaryGetCount(config->predefinedHttpHeaderValues);
        
        if (numKeys > 0) {
            CFTypeRef *keys = (CFTypeRef *) malloc(numKeys * sizeof(CFTypeRef));
            
            if (keys) {
                CFDictionaryGetKeysAndValues(config->predefinedHttpHeaderValues, (const void **) keys, NULL);
                
                for (CFIndex i=0; i < numKeys; i++) {
                    CFTypeRef key = keys[i];
                    
                    if (CFGetTypeID(key) == CFStringGetTypeID()) {
                        const void *value = CFDictionaryGetValue(config->predefinedHttpHeaderValues, (const void *) key);
                        
                        if (value) {
                            CFStringRef headerKey = (CFStringRef) key;
                            
                            CFTypeRef valueRef = (CFTypeRef) value;
                            
                            if (CFGetTypeID(valueRef) == CFStringGetTypeID()) {
                                CFStringRef headerValue = (CFStringRef) valueRef;
                                
                                HS_TRACE("Setting predefined HTTP header ");
                                HS_TRACE_CFSTRING(headerKey);
                                HS_TRACE_CFSTRING(headerValue);
                                
                                CFHTTPMessageSetHeaderFieldValue(request, headerKey, headerValue);
                            }
                        }
                    }
                }
                
                free(keys);
            }
        }
    }
    
    if (!(readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request))) {
        goto out;
    }
    
    CFReadStreamSetProperty(readStream,
                            kCFStreamNetworkServiceType,
                            kCFStreamNetworkServiceTypeBackground);
    
    CFReadStreamSetProperty(readStream,
                            kCFStreamPropertyHTTPShouldAutoredirect,
                            kCFBooleanTrue);
    
    proxySettings = CFNetworkCopySystemProxySettings();
    if (proxySettings) {
        CFReadStreamSetProperty(readStream, kCFStreamPropertyHTTPProxy, proxySettings);
        CFRelease(proxySettings);
    }
    
out:
    if (request) {
        CFRelease(request);
    }
    
    return readStream;
}
    
void HTTP_Stream::parseHttpHeadersIfNeeded(const UInt8 *buf, const CFIndex bufSize)
{
    if (m_httpHeadersParsed) {
        return;
    }
    m_httpHeadersParsed = true;
    
    /* If the response has the "ICY 200 OK" string,
     * we are dealing with the ShoutCast protocol.
     * The HTTP headers won't be available.
     */
    if (bufSize >= 10 &&
        buf[0] == 0x49 && buf[1] == 0x43 && buf[2] == 0x59 &&
        buf[3] == 0x20 && buf[4] == 0x32 && buf[5] == 0x30 &&
        buf[6] == 0x30 && buf[7] == 0x20 && buf[8] == 0x4F &&
        buf[9] == 0x4B) {
        m_icyStream = true;
        
        HS_TRACE("Detected an IceCast stream\n");
        
        // This is an ICY stream, don't try to parse the HTTP headers
        return;
    }
    
    HS_TRACE("A regular HTTP stream\n");
    
    CFHTTPMessageRef response = (CFHTTPMessageRef)CFReadStreamCopyProperty(m_readStream, kCFStreamPropertyHTTPResponseHeader);
    CFIndex statusCode = 0;
    
    if (response) {
        /*
         * If the server responded with the icy-metaint header, the response
         * body will be encoded in the ShoutCast protocol.
         */
        CFStringRef icyMetaIntString = CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("icy-metaint"));
        if (icyMetaIntString) {
            m_icyStream = true;
            m_icyHeadersParsed = true;
            m_icyHeadersRead = true;
            m_icyMetaDataInterval = CFStringGetIntValue(icyMetaIntString);
            CFRelease(icyMetaIntString);
        }
        
        HS_TRACE("icy-metaint: %zu\n", m_icyMetaDataInterval);
        
        statusCode = CFHTTPMessageGetResponseStatusCode(response);
        
        HS_TRACE("HTTP response code %zu", statusCode);
        
        CFStringRef icyNameString = CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("icy-name"));
        if (icyNameString) {
            if (m_icyName) {
                CFRelease(m_icyName);
            }
            m_icyName = icyNameString;
            
            if (m_delegate) {
                std::map<CFStringRef,CFStringRef> metadataMap;
                
                metadataMap[CFSTR("IcecastStationName")] = CFStringCreateCopy(kCFAllocatorDefault, m_icyName);
                
                m_delegate->streamMetaDataAvailable(metadataMap);
            }
        }
        
        if (m_contentType) {
            CFRelease(m_contentType);
        }
        
        m_contentType = CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("Content-Type"));
        
        HS_TRACE("Content-type: ");
        HS_TRACE_CFSTRING(m_contentType);
        
        CFStringRef contentLengthString = CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("Content-Length"));
        if (contentLengthString) {
            m_contentLength = CFStringGetIntValue(contentLengthString);
            
            CFRelease(contentLengthString);
        }
        
        CFRelease(response);
    }
       
    if (m_delegate &&
        (statusCode == 200 || statusCode == 206)) {
        m_delegate->streamIsReadyRead();
    } else {
        if (m_delegate) {
            CFStringRef statusCodeString = CFStringCreateWithFormat(NULL,
                                                                    NULL,
                                                                    CFSTR("HTTP response code %d"),
                                                                    (unsigned int)statusCode);
            m_delegate->streamErrorOccurred(statusCodeString);
            
            if (statusCodeString) {
                CFRelease(statusCodeString);
            }
        }
    }
}
    
void HTTP_Stream::parseICYStream(const UInt8 *buf, const CFIndex bufSize)
{
    HS_TRACE("Parsing an IceCast stream, received %li bytes\n", bufSize);
    
    CFIndex offset = 0;
    CFIndex bytesFound = 0;
    if (!m_icyHeadersRead) {
        HS_TRACE("ICY headers not read, reading\n");
        
        for (; offset < bufSize; offset++) {
            if (m_icyHeaderCR && buf[offset] == '\n') {
                if (bytesFound > 0) {
                    m_icyHeaderLines.push_back(createMetaDataStringWithMostReasonableEncoding(&buf[offset-bytesFound-1], bytesFound));
                    
                    bytesFound = 0;
                    
                    HS_TRACE_CFSTRING(m_icyHeaderLines[m_icyHeaderLines.size()-1]);
                    
                    continue;
                }
                
                HS_TRACE("End of ICY headers\n");
                
                m_icyHeadersRead = true;
                break;
            }
            
            if (buf[offset] == '\r') {
                m_icyHeaderCR = true;
                continue;
            } else {
                m_icyHeaderCR = false;
            }
            
            bytesFound++;
        }
    } else if (!m_icyHeadersParsed) {
        HS_TRACE("ICY headers not parsed, parsing\n");
        
        const CFStringRef icyContentTypeHeader = CFSTR("content-type:");
        const CFStringRef icyMetaDataHeader    =  CFSTR("icy-metaint:");
        const CFStringRef icyNameHeader        = CFSTR("icy-name:");

        const CFIndex icyContenTypeHeaderLength = CFStringGetLength(icyContentTypeHeader);
        const CFIndex icyMetaDataHeaderLength   = CFStringGetLength(icyMetaDataHeader);
        const CFIndex icyNameHeaderLength       = CFStringGetLength(icyNameHeader);
        
        for (std::vector<CFStringRef>::iterator h = m_icyHeaderLines.begin(); h != m_icyHeaderLines.end(); ++h) {
            CFStringRef line = *h;
            const CFIndex lineLength = CFStringGetLength(line);
            
            if (lineLength == 0) {
                continue;
            }
            
            HS_TRACE_CFSTRING(line);
            
            if (CFStringCompareWithOptions(line,
                                           icyContentTypeHeader,
                                           CFRangeMake(0, icyContenTypeHeaderLength),
                                           0) == kCFCompareEqualTo) {
                if (m_contentType) {
                    CFRelease(m_contentType), m_contentType = 0;
                }
                m_contentType = CFStringCreateWithSubstring(kCFAllocatorDefault,
                                                            line,
                                                            CFRangeMake(icyContenTypeHeaderLength, lineLength - icyContenTypeHeaderLength));
                
            }
            
            if (CFStringCompareWithOptions(line,
                                           icyMetaDataHeader,
                                           CFRangeMake(0, icyMetaDataHeaderLength),
                                           0) == kCFCompareEqualTo) {
                CFStringRef metadataInterval = CFStringCreateWithSubstring(kCFAllocatorDefault,
                                                                           line,
                                                                           CFRangeMake(icyMetaDataHeaderLength, lineLength - icyMetaDataHeaderLength));
                
                if (metadataInterval) {
                    m_icyMetaDataInterval = CFStringGetIntValue(metadataInterval);
                    
                    CFRelease(metadataInterval);
                } else {
                    m_icyMetaDataInterval = 0;
                }
            }
            
            if (CFStringCompareWithOptions(line,
                                           icyNameHeader,
                                           CFRangeMake(0, icyNameHeaderLength),
                                           0) == kCFCompareEqualTo) {
                if (m_icyName) {
                    CFRelease(m_icyName);
                }
                
                m_icyName = CFStringCreateWithSubstring(kCFAllocatorDefault,
                                                        line,
                                                        CFRangeMake(icyNameHeaderLength, lineLength - icyNameHeaderLength));
            }
        }
        
        m_icyHeadersParsed = true;
        offset++;
        
        if (m_delegate) {
            m_delegate->streamIsReadyRead();
        }
    }
    
    Stream_Configuration *config = Stream_Configuration::configuration();
    
    if (!m_icyReadBuffer) {
        m_icyReadBuffer = new UInt8[config->httpConnectionBufferSize];
    }
    
    HS_TRACE("Reading ICY stream for playback\n");
    
    UInt32 i=0;
    
    for (; offset < bufSize; offset++) {
        // is this a metadata byte?
        if (m_metaDataBytesRemaining > 0) {
            m_metaDataBytesRemaining--;
            
            if (m_metaDataBytesRemaining == 0) {
                m_dataByteReadCount = 0;
                
                if (m_delegate && !m_icyMetaData.empty()) {
                    std::map<CFStringRef,CFStringRef> metadataMap;
                    
                    CFStringRef metaData = createMetaDataStringWithMostReasonableEncoding(&m_icyMetaData[0],
                                                                                          m_icyMetaData.size());
                    
                    if (!metaData) {
                        // Metadata encoding failed, cannot parse.
                        m_icyMetaData.clear();
                        continue;
                    }
                    
                    CFArrayRef tokens = CFStringCreateArrayBySeparatingStrings(kCFAllocatorDefault,
                                                                               metaData,
                                                                               CFSTR(";"));
                    
                    for (CFIndex i=0, max=CFArrayGetCount(tokens); i < max; i++) {
                        CFStringRef token = (CFStringRef) CFArrayGetValueAtIndex(tokens, i);
                        
                        CFRange foundRange;
                        
                        if (CFStringFindWithOptions(token,
                                                    CFSTR("='"),
                                                    CFRangeMake(0, CFStringGetLength(token)),
                                                    NULL,
                                                    &foundRange) == true) {
                            
                            CFRange keyRange = CFRangeMake(0, foundRange.location);
                            
                            CFStringRef metadaKey = CFStringCreateWithSubstring(kCFAllocatorDefault,
                                                                                token,
                                                                                keyRange);
                            
                            CFRange valueRange = CFRangeMake(foundRange.location + 2, CFStringGetLength(token) - keyRange.length - 3);
                            
                            CFStringRef metadaValue = CFStringCreateWithSubstring(kCFAllocatorDefault,
                                                                                  token,
                                                                                  valueRange);
                            
                            metadataMap[metadaKey] = metadaValue;
                        }
                    }
                    
                    CFRelease(tokens);
                    CFRelease(metaData);
                    
                    if (m_icyName) {
                        metadataMap[CFSTR("IcecastStationName")] = CFStringCreateCopy(kCFAllocatorDefault, m_icyName);
                    }
                    
                    m_delegate->streamMetaDataAvailable(metadataMap);
                }
                m_icyMetaData.clear();
                continue;
            }
            
            m_icyMetaData.push_back(buf[offset]);
            continue;
        }
        
        // is this the interval byte?
        if (m_icyMetaDataInterval > 0 && m_dataByteReadCount == m_icyMetaDataInterval) {
            m_metaDataBytesRemaining = buf[offset] * 16;
            
            if (m_metaDataBytesRemaining == 0) {
                m_dataByteReadCount = 0;
            }
            continue;
        }
        
        // a data byte
        m_dataByteReadCount++;
        m_icyReadBuffer[i++] = buf[offset];
    }
    
    if (m_delegate && i > 0) {
        m_delegate->streamHasBytesAvailable(m_icyReadBuffer, i);
    }
}
    
#define TRY_ENCODING(STR,ENC) STR = CFStringCreateWithBytes(kCFAllocatorDefault, bytes, numBytes, ENC, false); \
    if (STR != NULL) { return STR; }
    
CFStringRef HTTP_Stream::createMetaDataStringWithMostReasonableEncoding(const UInt8 *bytes, const CFIndex numBytes)
{
    CFStringRef metaData;
    
    TRY_ENCODING(metaData, kCFStringEncodingUTF8);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatin1);
    TRY_ENCODING(metaData, kCFStringEncodingWindowsLatin1);
    TRY_ENCODING(metaData, kCFStringEncodingNextStepLatin);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatin2);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatin3);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatin4);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatinCyrillic);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatinArabic);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatinGreek);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatinHebrew);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatin5);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatin6);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatinThai);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatin7);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatin8);
    TRY_ENCODING(metaData, kCFStringEncodingISOLatin9);
    TRY_ENCODING(metaData, kCFStringEncodingWindowsLatin2);
    TRY_ENCODING(metaData, kCFStringEncodingWindowsCyrillic);
    TRY_ENCODING(metaData, kCFStringEncodingWindowsGreek);
    TRY_ENCODING(metaData, kCFStringEncodingWindowsLatin5);
    TRY_ENCODING(metaData, kCFStringEncodingWindowsHebrew);
    TRY_ENCODING(metaData, kCFStringEncodingWindowsArabic);
    TRY_ENCODING(metaData, kCFStringEncodingKOI8_R);
    TRY_ENCODING(metaData, kCFStringEncodingBig5);
    TRY_ENCODING(metaData, kCFStringEncodingASCII);
    
    return metaData;
}
    
#undef TRY_ENCODING
    
void HTTP_Stream::readCallBack(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo)
{
    HTTP_Stream *THIS = static_cast<HTTP_Stream*>(clientCallBackInfo);
    
    Stream_Configuration *config = Stream_Configuration::configuration();
    
    CFStringRef reportedNetworkError = NULL;
    
    switch (eventType) {
        case kCFStreamEventHasBytesAvailable: {
            if (!THIS->m_httpReadBuffer) {
                THIS->m_httpReadBuffer = new UInt8[config->httpConnectionBufferSize];
            }
            
            while (CFReadStreamHasBytesAvailable(stream)) {
                if (!THIS->m_scheduledInRunLoop) {
                    /*
                     * This is critical - though the stream has data available,
                     * do not try to feed the audio queue with data, if it has
                     * indicated that it doesn't want more data due to buffers
                     * full.
                     */
                    THIS->m_readPending = true;
                    break;
                }
                
                CFIndex bytesRead = CFReadStreamRead(stream, THIS->m_httpReadBuffer, config->httpConnectionBufferSize);
                
                if (CFReadStreamGetStatus(stream) == kCFStreamStatusError ||
                    bytesRead < 0) {
                    if (THIS->contentLength() > 0) {
                        /*
                         * Try to recover gracefully if we have a non-continuous stream
                         */
                        Input_Stream_Position currentPosition = THIS->position();
                        
                        Input_Stream_Position recoveryPosition;
                        recoveryPosition.start = currentPosition.start + THIS->m_bytesRead;
                        recoveryPosition.end = THIS->contentLength();
                        
                        HS_TRACE("Recovering HTTP stream, start %llu\n", recoveryPosition.start);
                        
                        THIS->open(recoveryPosition);
                        
                        break;
                    }
                    
                    CFErrorRef streamError = CFReadStreamCopyError(stream);
                    
                    if (streamError) {
                        CFStringRef errorDesc = CFErrorCopyDescription(streamError);
                        
                        if (errorDesc) {
                            reportedNetworkError = CFStringCreateCopy(kCFAllocatorDefault, errorDesc);
                            
                            CFRelease(errorDesc);
                        }
                        
                        CFRelease(streamError);
                    }
                    
                    if (THIS->m_delegate) {
                        THIS->m_delegate->streamErrorOccurred(reportedNetworkError);
                        
                        if (reportedNetworkError) {
                            CFRelease(reportedNetworkError), reportedNetworkError = NULL;
                        }
                    }
                    break;
                }
                
                if (bytesRead > 0) {
                    THIS->m_bytesRead += bytesRead;
                    
                    HS_TRACE("Read %li bytes, total %llu\n", bytesRead, THIS->m_bytesRead);
                    
                    THIS->parseHttpHeadersIfNeeded(THIS->m_httpReadBuffer, bytesRead);
                    
    #ifdef INCLUDE_ID3TAG_SUPPORT
                    if (!THIS->m_icyStream && THIS->m_id3Parser->wantData()) {
                        THIS->m_id3Parser->feedData(THIS->m_httpReadBuffer, (UInt32)bytesRead);
                    }
    #endif
                    
                    if (THIS->m_icyStream) {
                        HS_TRACE("Parsing ICY stream\n");
                        
                        THIS->parseICYStream(THIS->m_httpReadBuffer, bytesRead);
                    } else {
                        if (THIS->m_delegate) {
                            HS_TRACE("Not an ICY stream; calling the delegate back\n");
                            
                            THIS->m_delegate->streamHasBytesAvailable(THIS->m_httpReadBuffer, (UInt32)bytesRead);
                        }
                    }
                }
            }
            
            if (reportedNetworkError) {
                CFRelease(reportedNetworkError), reportedNetworkError = NULL;
            }
            
            break;
        }
        case kCFStreamEventEndEncountered: {
            if (THIS->m_delegate) {
                THIS->m_delegate->streamEndEncountered();
            }
            break;
        }
        case kCFStreamEventErrorOccurred: {
            if (THIS->m_delegate) {
                CFStringRef reportedNetworkError = NULL;
                CFErrorRef streamError = CFReadStreamCopyError(stream);
                
                if (streamError) {
                    CFStringRef errorDesc = CFErrorCopyDescription(streamError);
                    
                    if (errorDesc) {
                        reportedNetworkError = CFStringCreateCopy(kCFAllocatorDefault, errorDesc);
                        
                        CFRelease(errorDesc);
                    }
                    
                    CFRelease(streamError);
                }
                
                THIS->m_delegate->streamErrorOccurred(reportedNetworkError);
                if (reportedNetworkError) {
                    CFRelease(reportedNetworkError);
                }
            }
            break;
        }
    }
}

}  // namespace astreamer
