/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#ifndef ASTREAMER_INPUT_STREAM_H
#define ASTREAMER_INPUT_STREAM_H

#import "id3_parser.h"

namespace astreamer {

class Input_Stream_Delegate;
    
struct Input_Stream_Position {
    UInt64 start;
    UInt64 end;
};
    
class Input_Stream : public ID3_Parser_Delegate {
public:
    Input_Stream();
    virtual ~Input_Stream();
    
    Input_Stream_Delegate* m_delegate;
    
    virtual Input_Stream_Position position() = 0;
    
    virtual CFStringRef contentType() = 0;
    virtual size_t contentLength() = 0;
    
    virtual bool open() = 0;
    virtual bool open(const Input_Stream_Position& position) = 0;
    virtual void close() = 0;
    
    virtual void setScheduledInRunLoop(bool scheduledInRunLoop) = 0;
    
    virtual void setUrl(CFURLRef url) = 0;
};

class Input_Stream_Delegate {
public:
    virtual void streamIsReadyRead() = 0;
    virtual void streamHasBytesAvailable(UInt8 *data, UInt32 numBytes) = 0;
    virtual void streamEndEncountered() = 0;
    virtual void streamErrorOccurred(CFStringRef errorDesc) = 0;
    virtual void streamMetaDataAvailable(std::map<CFStringRef,CFStringRef> metaData) = 0;
    virtual void streamMetaDataByteSizeAvailable(UInt32 sizeInBytes) = 0;
};

} // namespace astreamer

#endif // ASTREAMER_INPUT_STREAM_H