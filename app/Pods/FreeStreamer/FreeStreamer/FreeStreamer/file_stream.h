/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#ifndef ASTREAMER_FILE_STREAM_H
#define ASTREAMER_FILE_STREAM_H

#import "input_stream.h"
#import "id3_parser.h"

namespace astreamer {
    
class File_Stream : public Input_Stream {
private:
    
    File_Stream(const File_Stream&);
    File_Stream& operator=(const File_Stream&);
    
    CFURLRef m_url;
    CFReadStreamRef m_readStream;
    bool m_scheduledInRunLoop;
    bool m_readPending;
    Input_Stream_Position m_position;
    
    UInt8 *m_fileReadBuffer;
    
    ID3_Parser *m_id3Parser;
    
    CFStringRef m_contentType;
    
    static void readCallBack(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo);
    
public:
    File_Stream();
    virtual ~File_Stream();
    
    Input_Stream_Position position();
    
    CFStringRef contentType();
    void setContentType(CFStringRef contentType);
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

#endif // ASTREAMER_FILE_STREAM_H