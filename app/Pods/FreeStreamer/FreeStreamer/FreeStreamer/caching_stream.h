/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#ifndef ASTREAMER_CACHING_STREAM_H
#define ASTREAMER_CACHING_STREAM_H

#include "input_stream.h"

namespace astreamer {
    
class File_Output;
class File_Stream;
    
class Caching_Stream : public Input_Stream, public Input_Stream_Delegate {
private:
    Input_Stream *m_target;
    File_Output *m_fileOutput;
    File_Stream *m_fileStream;
    bool m_cacheable;
    bool m_writable;
    bool m_useCache;
    bool m_cacheMetaDataWritten;
    CFStringRef m_cacheIdentifier;
    CFURLRef m_fileUrl;
    CFURLRef m_metaDataUrl;
    
private:
    CFURLRef createFileURLWithPath(CFStringRef path);
    
    void readMetaData();
    
public:
    Caching_Stream(Input_Stream *target);
    virtual ~Caching_Stream();
    
    Input_Stream_Position position();
    
    CFStringRef contentType();
    size_t contentLength();
    
    bool open();
    bool open(const Input_Stream_Position& position);
    void close();
    
    void setScheduledInRunLoop(bool scheduledInRunLoop);
    
    void setUrl(CFURLRef url);
    
    void setCacheIdentifier(CFStringRef cacheIdentifier);
    
    static bool canHandleUrl(CFURLRef url);
    
    /* ID3_Parser_Delegate */
    void id3metaDataAvailable(std::map<CFStringRef,CFStringRef> metaData);
    void id3tagSizeAvailable(UInt32 tagSize);
    
    void streamIsReadyRead();
    void streamHasBytesAvailable(UInt8 *data, UInt32 numBytes);
    void streamEndEncountered();
    void streamErrorOccurred(CFStringRef errorDesc);
    void streamMetaDataAvailable(std::map<CFStringRef,CFStringRef> metaData);
    void streamMetaDataByteSizeAvailable(UInt32 sizeInBytes);
};
    
    
} // namespace astreamer

#endif /* ASTREAMER_CACHING_STREAM_H */
