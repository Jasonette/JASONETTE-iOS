/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2018 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#include "file_stream.h"
#include "stream_configuration.h"

namespace astreamer {
    
File_Stream::File_Stream() :
    m_url(0),
    m_readStream(0),
    m_scheduledInRunLoop(false),
    m_readPending(false),
    m_fileReadBuffer(0),
    m_id3Parser(new ID3_Parser()),
    m_contentType(0)
{
    m_id3Parser->m_delegate = this;
}
    
File_Stream::~File_Stream()
{
    close();
    
    if (m_fileReadBuffer) {
        delete [] m_fileReadBuffer;
        m_fileReadBuffer = 0;
    }
    
    if (m_url) {
        CFRelease(m_url);
        m_url = 0;
    }
    
    delete m_id3Parser;
    m_id3Parser = 0;
    
    if (m_contentType) {
        CFRelease(m_contentType);
    }
}
    
Input_Stream_Position File_Stream::position()
{
    return m_position;
}
    
CFStringRef File_Stream::contentType()
{
    if (m_contentType) {
        // Use the provided content type
        return m_contentType;
    }
    
    // Try to resolve the content type from the file
    
    CFStringRef contentType = CFSTR("");
    CFStringRef pathComponent = 0;
    CFIndex len = 0;
    CFRange range;
    CFStringRef suffix = 0;
    
    if (!m_url) {
        goto done;
    }
    
    pathComponent = CFURLCopyLastPathComponent(m_url);
    
    if (!pathComponent) {
        goto done;
    }
    
    len = CFStringGetLength(pathComponent);
    
    if (len > 5) {
        range.length = 4;
        range.location = len - 4;
        
        suffix = CFStringCreateWithSubstring(kCFAllocatorDefault,
                                             pathComponent,
                                             range);
        
        if (!suffix) {
            goto done;
        }
        
        // TODO: we should do the content-type resolvation in a better way.
        if (CFStringCompare(suffix, CFSTR(".mp3"), 0) == kCFCompareEqualTo) {
            contentType = CFSTR("audio/mpeg");
        } else if (CFStringCompare(suffix, CFSTR(".m4a"), 0) == kCFCompareEqualTo) {
            contentType = CFSTR("audio/x-m4a");
        } else if (CFStringCompare(suffix, CFSTR(".mp4"), 0) == kCFCompareEqualTo) {
            contentType = CFSTR("audio/mp4");
        } else if (CFStringCompare(suffix, CFSTR(".aac"), 0) == kCFCompareEqualTo) {
            contentType = CFSTR("audio/aac");
        }
    }
    
done:
    if (pathComponent) {
        CFRelease(pathComponent);
    }
    if (suffix) {
        CFRelease(suffix);
    }
    
    return contentType;
}
    
void File_Stream::setContentType(CFStringRef contentType)
{
    if (m_contentType) {
        CFRelease(m_contentType);
        m_contentType = 0;
    }
    if (contentType) {
        m_contentType = CFStringCreateCopy(kCFAllocatorDefault, contentType);
    }
}
    
size_t File_Stream::contentLength()
{
    CFNumberRef length = NULL;
    CFErrorRef err = NULL;

    if (CFURLCopyResourcePropertyForKey(m_url, kCFURLFileSizeKey, &length, &err)) {
        CFIndex fileLength;
        if (CFNumberGetValue(length, kCFNumberCFIndexType, &fileLength)) {
            CFRelease(length);
            
            return fileLength;
        }
    }
    return 0;
}
    
bool File_Stream::open()
{
    Input_Stream_Position position;
    position.start = 0;
    position.end = 0;
    
    m_id3Parser->reset();
    
    return open(position);
}
    
bool File_Stream::open(const Input_Stream_Position& position)
{
    bool success = false;
    CFStreamClientContext CTX = { 0, this, NULL, NULL, NULL };
    
    /* Already opened a read stream, return */
    if (m_readStream) {
        goto out;
    }
    
    if (!m_url) {
        goto out;
    }
    
    /* Reset state */
    m_position = position;
    
    m_readPending = false;
	
    /* Failed to create a stream */
    if (!(m_readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, m_url))) {
        goto out;
    }
    
    if (m_position.start > 0) {
        CFNumberRef position = CFNumberCreate(0, kCFNumberLongLongType, &m_position.start);
        CFReadStreamSetProperty(m_readStream, kCFStreamPropertyFileCurrentOffset, position);
        CFRelease(position);
    }
    
    if (!CFReadStreamSetClient(m_readStream, kCFStreamEventHasBytesAvailable |
                               kCFStreamEventEndEncountered |
                               kCFStreamEventErrorOccurred, readCallBack, &CTX)) {
        CFRelease(m_readStream);
        m_readStream = 0;
        goto out;
    }
    
    setScheduledInRunLoop(true);
    
    if (!CFReadStreamOpen(m_readStream)) {
        /* Open failed: clean */
        CFReadStreamSetClient(m_readStream, 0, NULL, NULL);
        setScheduledInRunLoop(false);
        if (m_readStream) {
            CFRelease(m_readStream);
            m_readStream = 0;
        }
        goto out;
    }
    
    success = true;
    
out:
    
    if (success) {
        if (m_delegate) {
            m_delegate->streamIsReadyRead();
        }
    }
    return success;
}
    
void File_Stream::close()
{
    /* The stream has been already closed */
    if (!m_readStream) {
        return;
    }
    
    CFReadStreamSetClient(m_readStream, 0, NULL, NULL);
    setScheduledInRunLoop(false);
    CFReadStreamClose(m_readStream);
    CFRelease(m_readStream);
    m_readStream = 0;
}
    
void File_Stream::setScheduledInRunLoop(bool scheduledInRunLoop)
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
    
void File_Stream::setUrl(CFURLRef url)
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
    
bool File_Stream::canHandleUrl(CFURLRef url)
{
    if (!url) {
        return false;
    }
    
    CFStringRef scheme = CFURLCopyScheme(url);
    
    if (scheme) {
        if (CFStringCompare(scheme, CFSTR("file"), 0) == kCFCompareEqualTo) {
            CFRelease(scheme);
            // The only scheme we claim to handle are the local files
            return true;
        }
        
        CFRelease(scheme);
    }
    
    // We don't handle anything else but local files
    return false;
}
    
/* ID3_Parser_Delegate */
void File_Stream::id3metaDataAvailable(std::map<CFStringRef,CFStringRef> metaData)
{
    if (m_delegate) {
        m_delegate->streamMetaDataAvailable(metaData);
    }
}
    
void File_Stream::id3tagSizeAvailable(UInt32 tagSize)
{
    if (m_delegate) {
        m_delegate->streamMetaDataByteSizeAvailable(tagSize);
    }
}
    
void File_Stream::readCallBack(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo)
{
    File_Stream *THIS = static_cast<File_Stream*>(clientCallBackInfo);
    
    Stream_Configuration *config = Stream_Configuration::configuration();
    
    switch (eventType) {
        case kCFStreamEventHasBytesAvailable: {
            if (!THIS->m_fileReadBuffer) {
                THIS->m_fileReadBuffer = new UInt8[config->httpConnectionBufferSize];
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
                
                CFIndex bytesRead = CFReadStreamRead(stream, THIS->m_fileReadBuffer, config->httpConnectionBufferSize);
                
                if (CFReadStreamGetStatus(stream) == kCFStreamStatusError ||
                    bytesRead < 0) {
                    
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
                
                if (bytesRead > 0) {
                    if (THIS->m_delegate) {
                        THIS->m_delegate->streamHasBytesAvailable(THIS->m_fileReadBuffer, (UInt32)bytesRead);
                    }
                    
                    if (THIS->m_id3Parser->wantData()) {
                        THIS->m_id3Parser->feedData(THIS->m_fileReadBuffer, (UInt32)bytesRead);
                    }
                }
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
    
} // namespace astreamer
