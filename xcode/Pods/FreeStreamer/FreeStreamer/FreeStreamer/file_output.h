/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#ifndef ASTREAMER_FILE_OUTPUT_H
#define ASTREAMER_FILE_OUTPUT_H

#import <CoreFoundation/CoreFoundation.h>

namespace astreamer {

class File_Output  {
private:
    File_Output(const File_Output&);
    File_Output& operator=(const File_Output&);
    
    CFWriteStreamRef m_writeStream;
    
public:
    File_Output(CFURLRef fileURL);
    ~File_Output();
    
    CFIndex write(const UInt8 *buffer, CFIndex bufferLength);
};

} // namespace astreamer

#endif // ASTREAMER_FILE_OUTPUT_H