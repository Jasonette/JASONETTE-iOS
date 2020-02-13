/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2018 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#ifndef ASTREAMER_HTTP_STREAM_H
#define ASTREAMER_HTTP_STREAM_H

#import <CFNetwork/CFNetwork.h>
#import <vector>
#import <map>
#import "input_stream.h"
#import "id3_parser.h"

namespace astreamer {

class HTTP_Stream : public Input_Stream {
private:
    
    HTTP_Stream(const HTTP_Stream&);
    HTTP_Stream& operator=(const HTTP_Stream&);
    
    static CFStringRef httpRequestMethod;
    static CFStringRef httpUserAgentHeader;
    static CFStringRef httpRangeHeader;
    static CFStringRef icyMetaDataHeader;
    static CFStringRef icyMetaDataValue;
    
    CFURLRef m_url;
    CFReadStreamRef m_readStream;
    bool m_scheduledInRunLoop;
    bool m_readPending;
    Input_Stream_Position m_position;
    
    /* HTTP headers */
    bool m_httpHeadersParsed;
    CFStringRef m_contentType;
    size_t m_contentLength;
    UInt64 m_bytesRead;
    
    /* ICY protocol */
    bool m_icyStream;
    bool m_icyHeaderCR;
    bool m_icyHeadersRead;
    bool m_icyHeadersParsed;
    
    CFStringRef m_icyName;
    
    std::vector<CFStringRef> m_icyHeaderLines;
    size_t m_icyMetaDataInterval;
    size_t m_dataByteReadCount;
    size_t m_metaDataBytesRemaining;
    
    std::vector<UInt8> m_icyMetaData;
    
    /* Read buffers */
    UInt8 *m_httpReadBuffer;
    UInt8 *m_icyReadBuffer;
    
    ID3_Parser *m_id3Parser;
    
    CFReadStreamRef createReadStream(CFURLRef url);
    void parseHttpHeadersIfNeeded(const UInt8 *buf, const CFIndex bufSize);
    void parseICYStream(const UInt8 *buf, const CFIndex bufSize);
    CFStringRef createMetaDataStringWithMostReasonableEncoding(const UInt8 *bytes, const CFIndex numBytes);
    
    static void readCallBack(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo);
    
public:
    HTTP_Stream();
    virtual ~HTTP_Stream();
    
    Input_Stream_Position position();
    
    CFStringRef contentType();
    size_t contentLength();
    
    bool open();
    bool open(const Input_Stream_Position& position);
    void close();
    
    void setScheduledInRunLoop(bool scheduledInRunLoop);
    
    void setUrl(CFURLRef url);
    
    static bool canHandleUrl(CFURLRef url);
    
    /* ID3_Parser_Delegate */
    void id3metaDataAvailable(std::map<CFStringRef,CFStringRef> metaData);
    void id3tagSizeAvailable(UInt32 tagSize);
};

} // namespace astreamer

#endif // ASTREAMER_HTTP_STREAM_H
