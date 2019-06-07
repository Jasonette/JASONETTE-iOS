/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#include "file_output.h"

namespace astreamer {

File_Output::File_Output(CFURLRef fileURL) :
    m_writeStream(CFWriteStreamCreateWithFile(kCFAllocatorDefault, fileURL))
{
    CFWriteStreamOpen(m_writeStream);
}
    
File_Output::~File_Output()
{
    CFWriteStreamClose(m_writeStream);
    CFRelease(m_writeStream);
}
    
CFIndex File_Output::write(const UInt8 *buffer, CFIndex bufferLength)
{
    return CFWriteStreamWrite(m_writeStream, buffer, bufferLength);
}

} // namespace astreamer