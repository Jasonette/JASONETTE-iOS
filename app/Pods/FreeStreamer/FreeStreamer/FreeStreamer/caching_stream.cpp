/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#include "caching_stream.h"
#include "file_output.h"
#include "stream_configuration.h"
#include "file_stream.h"

//#define CS_DEBUG 1

#if !defined (CS_DEBUG)
#define CS_TRACE(...) do {} while (0)
#define CS_TRACE_CFSTRING(X) do {} while (0)
#define CS_TRACE_CFURL(X) do {} while (0)
#else
#define CS_TRACE(...) printf(__VA_ARGS__)
#define CS_TRACE_CFSTRING(X) CS_TRACE("%s\n", CFStringGetCStringPtr(X, kCFStringEncodingMacRoman))
#define CS_TRACE_CFURL(X) CS_TRACE_CFSTRING(CFURLGetString(X))
#endif

namespace astreamer {
    
Caching_Stream::Caching_Stream(Input_Stream *target) :
    m_target(target),
    m_fileOutput(0),
    m_fileStream(new File_Stream()),
    m_cacheable(false),
    m_writable(false),
    m_useCache(false),
    m_cacheMetaDataWritten(false),
    m_cacheIdentifier(0),
    m_fileUrl(0),
    m_metaDataUrl(0)
{
    m_target->m_delegate = this;
    m_fileStream->m_delegate = this;
}

Caching_Stream::~Caching_Stream()
{
    if (m_target) {
        delete m_target, m_target = 0;
    }
    if (m_fileOutput) {
        delete m_fileOutput, m_fileOutput = 0;
    }
    if (m_fileStream) {
        delete m_fileStream, m_fileStream = 0;
    }
    if (m_cacheIdentifier) {
        CFRelease(m_cacheIdentifier), m_cacheIdentifier = 0;
    }
    if (m_fileUrl) {
        CFRelease(m_fileUrl), m_fileUrl = 0;
    }
    if (m_metaDataUrl) {
        CFRelease(m_metaDataUrl), m_fileUrl = 0;
    }
}
    
CFURLRef Caching_Stream::createFileURLWithPath(CFStringRef path)
{
    CFURLRef fileUrl = NULL;
    
    if (!path) {
        return fileUrl;
    }
    
    CFStringRef escapedPath = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, path, NULL, NULL, kCFStringEncodingUTF8);
    
    CFURLRef regularUrl = CFURLCreateWithString(kCFAllocatorDefault, (escapedPath ? escapedPath : path), NULL);
    
    if (regularUrl) {
        fileUrl = CFURLCreateFilePathURL(kCFAllocatorDefault, regularUrl, NULL);

        CFRelease(regularUrl);
    }
    
    if (escapedPath) {
        CFRelease(escapedPath);
    }
    
    return fileUrl;
}
    
void Caching_Stream::readMetaData()
{
    if (!m_metaDataUrl) {
        return;
    }
    
    CFReadStreamRef readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, m_metaDataUrl);
    
    if (readStream) {
        if (CFReadStreamOpen(readStream)) {
            
            UInt8 buf[1024];
            
            CFIndex bytesRead = CFReadStreamRead(readStream, buf, 1024);
            
            if (bytesRead > 0) {
                CFStringRef contentType = CFStringCreateWithBytes(kCFAllocatorDefault, buf, bytesRead, kCFStringEncodingUTF8, false);
                
                if (contentType) {
                    if (m_fileStream) {
                        CS_TRACE("Setting the content type of the file stream based on the meta data\n");
                        CS_TRACE_CFSTRING(contentType);
                        
                        m_fileStream->setContentType(contentType);
                    }
                    
                    CFRelease(contentType);
                }
            }
            
            CFReadStreamClose(readStream);
        }
        
        CFRelease(readStream);
    }
}

Input_Stream_Position Caching_Stream::position()
{
    if (m_useCache) {
        return m_fileStream->position();
    } else {
        return m_target->position();
    }
}

CFStringRef Caching_Stream::contentType()
{
    if (m_useCache) {
        return m_fileStream->contentType();
    } else {
        return m_target->contentType();
    }
}

size_t Caching_Stream::contentLength()
{
    if (m_useCache) {
        return m_fileStream->contentLength();
    } else {
        return m_target->contentLength();
    }
}

bool Caching_Stream::open()
{
    bool status;
    
    if (CFURLResourceIsReachable(m_metaDataUrl, NULL) &&
        CFURLResourceIsReachable(m_fileUrl, NULL)) {
        m_cacheable = false;
        m_writable  = false;
        m_useCache  = true;
        m_cacheMetaDataWritten = false;
        
        readMetaData();
        
        CS_TRACE("Playing file from cache\n");
        CS_TRACE_CFURL(m_fileUrl);
        
        status = m_fileStream->open();
    } else {
        m_cacheable = true;
        m_writable  = false;
        m_useCache  = false;
        m_cacheMetaDataWritten = false;
        
        CS_TRACE("File not cached\n");
    
        status = m_target->open();
    }
    
    return status;
}

bool Caching_Stream::open(const Input_Stream_Position& position)
{
    bool status;
    
    if (CFURLResourceIsReachable(m_metaDataUrl, NULL) &&
        CFURLResourceIsReachable(m_fileUrl, NULL)) {
        m_cacheable = false;
        m_writable  = false;
        m_useCache  = true;
        m_cacheMetaDataWritten = false;
        
        readMetaData();
        
        CS_TRACE("Playing file from cache\n");
        CS_TRACE_CFURL(m_fileUrl);
        
        status = m_fileStream->open(position);
    } else {
        m_cacheable = false;
        m_writable  = false;
        m_useCache  = false;
        m_cacheMetaDataWritten = false;
        
        CS_TRACE("File not cached\n");
        
        status = m_target->open(position);
    }
    
    return status;
}

void Caching_Stream::close()
{
    m_fileStream->close();
    m_target->close();
}

void Caching_Stream::setScheduledInRunLoop(bool scheduledInRunLoop)
{
    if (m_useCache) {
        m_fileStream->setScheduledInRunLoop(scheduledInRunLoop);
    } else {
        m_target->setScheduledInRunLoop(scheduledInRunLoop);
    }
}

void Caching_Stream::setUrl(CFURLRef url)
{
    m_target->setUrl(url);
}
    
void Caching_Stream::setCacheIdentifier(CFStringRef cacheIdentifier)
{
    m_cacheIdentifier = CFStringCreateCopy(kCFAllocatorDefault, cacheIdentifier);
    
    if (m_fileOutput) {
        delete m_fileOutput, m_fileOutput = 0;
    }
    
    Stream_Configuration *config = Stream_Configuration::configuration();
    
    CFStringRef filePath = CFStringCreateWithFormat(NULL, NULL, CFSTR("file://%@/%@"), config->cacheDirectory, m_cacheIdentifier);
    CFStringRef metaDataPath = CFStringCreateWithFormat(NULL, NULL, CFSTR("file://%@/%@.metadata"), config->cacheDirectory, m_cacheIdentifier);
    
    if (m_fileUrl) {
        CFRelease(m_fileUrl), m_fileUrl = 0;
    }
    if (m_metaDataUrl) {
        CFRelease(m_metaDataUrl), m_metaDataUrl = 0;
    }

    m_fileUrl = createFileURLWithPath(filePath);
    m_metaDataUrl = createFileURLWithPath(metaDataPath);
    
    m_fileStream->setUrl(m_fileUrl);
    
    CFRelease(filePath);
    CFRelease(metaDataPath);
}

bool Caching_Stream::canHandleUrl(CFURLRef url)
{
    if (!url) {
        return false;
    }
    
    CFStringRef scheme = CFURLCopyScheme(url);
    
    if (scheme) {
        if (CFStringCompare(scheme, CFSTR("http"), 0) == kCFCompareEqualTo) {
            CFRelease(scheme);
            // Using cache makes only sense for HTTP
            return true;
        }
        
        CFRelease(scheme);
    }
    
    // Nothing else to server
    return false;
}

/* ID3_Parser_Delegate */
void Caching_Stream::id3metaDataAvailable(std::map<CFStringRef,CFStringRef> metaData)
{
    if (m_delegate) {
        m_delegate->streamMetaDataAvailable(metaData);
    }
}
    
void Caching_Stream::id3tagSizeAvailable(UInt32 tagSize)
{
    if (m_delegate) {
        m_delegate->streamMetaDataByteSizeAvailable(tagSize);
    }
}

/* Input_Stream_Delegate */

void Caching_Stream::streamIsReadyRead()
{
    if (m_cacheable) {
        // If the stream is cacheable (not seeked from some position)
        // Check if the stream has a length. If there is no length,
        // it is a continuous stream and thus cannot be cached.
        m_cacheable = (m_target->contentLength() > 0);
    }
    
#if CS_DEBUG
    if (m_cacheable) CS_TRACE("Stream can be cached!\n");
    else CS_TRACE("Stream cannot be cached\n");
#endif
    
    if (m_delegate) {
        m_delegate->streamIsReadyRead();
    }
}
    
void Caching_Stream::streamHasBytesAvailable(UInt8 *data, UInt32 numBytes)
{
    if (m_cacheable) {
        if (numBytes > 0) {
            if (!m_fileOutput) {
                if (m_fileUrl) {
                    CS_TRACE("Caching started for stream\n");
                    
                    m_fileOutput = new File_Output(m_fileUrl);
                
                    m_writable = true;
                }
            }
            
            if (m_writable && m_fileOutput) {
                m_writable &= (m_fileOutput->write(data, numBytes) > 0);
            }
        }
    }
    if (m_delegate) {
        m_delegate->streamHasBytesAvailable(data, numBytes);
    }
}
    
void Caching_Stream::streamEndEncountered()
{
    if (m_fileOutput) {
        delete m_fileOutput, m_fileOutput = 0;
    }
    
    if (m_cacheable) {
        if (m_writable) {
            CS_TRACE("Successfully cached the stream\n");
            CS_TRACE_CFURL(m_fileUrl);
            
            // We only write the meta data if the stream was successfully streamed.
            // In that way we can use the meta data as an indicator that there is a file to stream.
            
            if (!m_cacheMetaDataWritten) {
                CFWriteStreamRef writeStream = CFWriteStreamCreateWithFile(kCFAllocatorDefault, m_metaDataUrl);
                
                if (writeStream) {
                    if (CFWriteStreamOpen(writeStream)) {
                        CFStringRef contentType = m_target->contentType();
                        
                        UInt8 buf[1024];
                        CFIndex usedBytes = 0;
                        
                        if (contentType) {
                            // It is possible that some streams don't provide a content type
                            CFStringGetBytes(contentType,
                                             CFRangeMake(0, CFStringGetLength(contentType)),
                                             kCFStringEncodingUTF8,
                                             '?',
                                             false,
                                             buf,
                                             1024,
                                             &usedBytes);
                        }
                        
                        if (usedBytes > 0) {
                            CS_TRACE("Writing the meta data\n");
                            CS_TRACE_CFSTRING(contentType);
                            
                            CFWriteStreamWrite(writeStream, buf, usedBytes);
                        }
                        
                        CFWriteStreamClose(writeStream);
                    }
                    
                    CFRelease(writeStream);
                }
                
                m_cacheable = false;
                m_writable  = false;
                m_useCache  = true;
                m_cacheMetaDataWritten = true;
            }
        }
    }
    if (m_delegate) {
        m_delegate->streamEndEncountered();
    }
}
    
void Caching_Stream::streamErrorOccurred(CFStringRef errorDesc)
{
    if (m_delegate) {
        m_delegate->streamErrorOccurred(errorDesc);
    }
}
    
void Caching_Stream::streamMetaDataAvailable(std::map<CFStringRef,CFStringRef> metaData)
{
    if (m_delegate) {
        m_delegate->streamMetaDataAvailable(metaData);
    }
}
    
void Caching_Stream::streamMetaDataByteSizeAvailable(UInt32 sizeInBytes)
{
    if (m_delegate) {
        m_delegate->streamMetaDataByteSizeAvailable(sizeInBytes);
    }
}

} // namespace astreamer