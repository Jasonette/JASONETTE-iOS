/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#ifndef ASTREAMER_ID3_PARSER_H
#define ASTREAMER_ID3_PARSER_H

#include <map>

#import <CFNetwork/CFNetwork.h>

namespace astreamer {

class ID3_Parser_Delegate;
class ID3_Parser_Private;

class ID3_Parser {
public:
    ID3_Parser();
    ~ID3_Parser();
    
    void reset();
    bool wantData();
    void feedData(UInt8 *data, UInt32 numBytes);
    
    ID3_Parser_Delegate *m_delegate;
    
private:
    ID3_Parser_Private *m_private;
};

class ID3_Parser_Delegate {
public:
    virtual void id3metaDataAvailable(std::map<CFStringRef,CFStringRef> metaData) = 0;
    virtual void id3tagSizeAvailable(UInt32 tagSize) = 0;
};
    
} // namespace astreamer

#endif // ASTREAMER_ID3_PARSER_H
