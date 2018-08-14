/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2016 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#include "id3_parser.h"

#include <vector>

//#define ID3_DEBUG 1

#if !defined ( ID3_DEBUG)
#define ID3_TRACE(...) do {} while (0)
#else
#define ID3_TRACE(...) printf(__VA_ARGS__)
#endif

namespace astreamer {

// Code from:
// http://www.opensource.apple.com/source/libsecurity_manifest/libsecurity_manifest-29384/lib/SecureDownloadInternal.c

// Returns a CFString containing the base64 representation of the data.
// boolean argument for whether to line wrap at 64 columns or not.
CFStringRef createBase64EncodedString(const UInt8* ptr, size_t len, int wrap) {
    const char* alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "abcdefghijklmnopqrstuvwxyz"
    "0123456789+/=";
    
    // base64 encoded data uses 4 ASCII characters to represent 3 octets.
    // There can be up to two == at the end of the base64 data for padding.
    // If we are line wrapping then we need space for one newline character
    // every 64 characters of output.
    // Rounded 4/3 up to 2 to avoid floating point math.
    
    //CFIndex max_len = (2*len) + 2;
    //if (wrap) len = len + ((2*len) / 64) + 1;
    
    CFMutableStringRef string = CFStringCreateMutable(NULL, 0);
    if (!string) return NULL;
    
    /*
     http://www.faqs.org/rfcs/rfc3548.html
     +--first octet--+-second octet--+--third octet--+
     |7 6 5 4 3 2 1 0|7 6 5 4 3 2 1 0|7 6 5 4 3 2 1 0|
     +-----------+---+-------+-------+---+-----------+
     |5 4 3 2 1 0|5 4 3 2 1 0|5 4 3 2 1 0|5 4 3 2 1 0|
     +--1.index--+--2.index--+--3.index--+--4.index--+
     */
    int i = 0;		// octet offset into input data
    int column = 0;		// output column number (used for line wrapping)
    for (;;) {
        UniChar c[16];	// buffer of characters to add to output
        int j = 0;	// offset to place next character in buffer
        int index;	// index into output alphabet
        
#define ADDCHAR(_X_) do { c[j++] = _X_; if (wrap && (++column == 64)) { column = 0; c[j++] = '\n'; } } while (0);
        
        // 1.index
        index = (ptr[i] >> 2) & 0x3F;
        ADDCHAR(alphabet[index]);
        
        // 2.index
        index = (ptr[i] << 4) & 0x30;
        if ((i+1) < len) {
            index = index | ((ptr[i+1] >> 4) & 0x0F);
            ADDCHAR(alphabet[index]);
        } else {	// end of input, pad as necessary
            ADDCHAR(alphabet[index]);
            ADDCHAR('=');
            ADDCHAR('=');
        }
        
        // 3.index
        if ((i+1) < len) {
            index = (ptr[i+1] << 2) & 0x3C;
            if ((i+2) < len) {
                index = index | ((ptr[i+2] >> 6) & 0x03);
                ADDCHAR(alphabet[index]);
            } else {	// end of input, pad as necessary
                ADDCHAR(alphabet[index]);
                ADDCHAR('=');
            }
        }
        
        // 4.index
        if ((i+2) < len) {
            index = (ptr[i+2]) & 0x3F;
            ADDCHAR(alphabet[index]);
        }
        
        CFStringAppendCharacters(string, c, j);
        i += 3; // we processed 3 bytes of input
        if (i >= len) {
            // end of data, append newline if we haven't already
            if (wrap && c[j-1] != '\n') {
                c[0] = '\n';
                CFStringAppendCharacters(string, c, 1);
            }
            break;
        }
    }
    return string;
}
    
enum ID3_Parser_State {
    ID3_Parser_State_Initial = 0,
    ID3_Parser_State_Parse_Frames,
    ID3_Parser_State_Tag_Parsed,
    ID3_Parser_State_Not_Valid_Tag
};
    
/*
 * =======================================
 * Private class
 * =======================================
 */
    
class ID3_Parser_Private {
public:
    ID3_Parser_Private();
    ~ID3_Parser_Private();
    
    bool wantData();
    void feedData(UInt8 *data, UInt32 numBytes);
    void setState(ID3_Parser_State state);
    void reset();
    
    CFStringRef parseContent(UInt32 framesize, UInt32 pos, CFStringEncoding encoding, bool byteOrderMark);
    
    ID3_Parser *m_parser;
    ID3_Parser_State m_state;
    UInt32 m_bytesReceived;
    UInt32 m_tagSize;
    UInt8 m_majorVersion;
    bool m_hasFooter;
    bool m_usesUnsynchronisation;
    bool m_usesExtendedHeader;
    CFStringRef m_title;
    CFStringRef m_performer;
    CFStringRef m_coverArt;
    
    std::vector<UInt8> m_tagData;
};
    
/*
 * =======================================
 * Private class implementation
 * =======================================
 */
    
ID3_Parser_Private::ID3_Parser_Private() :
    m_parser(0),
    m_state(ID3_Parser_State_Initial),
    m_bytesReceived(0),
    m_tagSize(0),
    m_majorVersion(0),
    m_hasFooter(false),
    m_usesUnsynchronisation(false),
    m_usesExtendedHeader(false),
    m_title(NULL),
    m_performer(NULL),
    m_coverArt(NULL)
{
}
    
ID3_Parser_Private::~ID3_Parser_Private()
{
    if (m_performer) {
        CFRelease(m_performer), m_performer = NULL;
    }
    if (m_title) {
        CFRelease(m_title), m_title = NULL;
    }
    if (m_coverArt) {
        CFRelease(m_coverArt), m_coverArt = NULL;
    }
}
    
bool ID3_Parser_Private::wantData()
{
    if (m_state == ID3_Parser_State_Tag_Parsed) {
        return false;
    }
    if (m_state == ID3_Parser_State_Not_Valid_Tag) {
        return false;
    }
    
    return true;
}
    
void ID3_Parser_Private::feedData(UInt8 *data, UInt32 numBytes)
{
    if (!wantData()) {
        return;
    }
    
    m_bytesReceived += numBytes;
    
    ID3_TRACE("received %i bytes, total bytes %i\n", numBytes, m_bytesReceived);
    
    for (CFIndex i=0; i < numBytes; i++) {
        m_tagData.push_back(data[i]);
    }
    
    bool enoughBytesToParse = true;
    
    while (enoughBytesToParse) {
        switch (m_state) {
            case ID3_Parser_State_Initial: {
                // Do we have enough bytes to determine if this is an ID3 tag or not?
                if (m_bytesReceived <= 9) {
                    enoughBytesToParse = false;
                    break;
                }
                
                if (!(m_tagData[0] == 'I' &&
                    m_tagData[1] == 'D' &&
                    m_tagData[2] == '3')) {
                    ID3_TRACE("Not an ID3 tag, bailing out\n");
                    
                    // Does not begin with the tag header; not an ID3 tag
                    setState(ID3_Parser_State_Not_Valid_Tag);
                    enoughBytesToParse = false;
                    break;
                }
                
                m_majorVersion = m_tagData[3];
                // Currently support only id3v2.2 and 2.3
                if (m_majorVersion != 2 && m_majorVersion != 3) {
                    ID3_TRACE("ID3v2.%i not supported by the parser\n", m_majorVersion);
                    
                    setState(ID3_Parser_State_Not_Valid_Tag);
                    enoughBytesToParse = false;
                    break;
                }
                
                // Ignore the revision
                
                // Parse the flags
                
                if ((m_tagData[5] & 0x80) != 0) {
                    m_usesUnsynchronisation = true;
                } else if ((m_tagData[5] & 0x40) != 0 && m_majorVersion >= 3) {
                    m_usesExtendedHeader = true;
                } else if ((m_tagData[5] & 0x10) != 0 && m_majorVersion >= 3) {
                    m_hasFooter = true;
                }
                
                m_tagSize = ((m_tagData[6] & 0x7F) << 21) | ((m_tagData[7] & 0x7F) << 14) |
                            ((m_tagData[8] & 0x7F) << 7) | (m_tagData[9] & 0x7F);
                
                if (m_tagSize > 0) {
                    if (m_hasFooter) {
                        m_tagSize += 10;
                    }
                    m_tagSize += 10;
                    
                    ID3_TRACE("tag size: %i\n", m_tagSize);
                    
                    if (m_parser->m_delegate) {
                        m_parser->m_delegate->id3tagSizeAvailable(m_tagSize);
                    }
                    
                    setState(ID3_Parser_State_Parse_Frames);
                    break;
                }
                
                setState(ID3_Parser_State_Not_Valid_Tag);
                enoughBytesToParse = false;
                break;
            }
                
            case ID3_Parser_State_Parse_Frames: {
                // Do we have enough data to parse the frames?
                if (m_tagData.size() < m_tagSize) {
                    ID3_TRACE("Not enough data received for parsing, have %lu bytes, need %i bytes\n",
                              m_tagData.size(),
                              m_tagSize);
                    enoughBytesToParse = false;
                    break;
                }
                
                UInt32 pos = 10;
                
                // Do we have an extended header? If we do, skip it
                if (m_usesExtendedHeader) {
                    UInt32 extendedHeaderSize = ((m_tagData[pos] << 21) |
                                                 (m_tagData[pos+1] << 14) |
                                                 (m_tagData[pos+2] << 7) |
                                                 m_tagData[pos+3]);
                    
                    if (pos + extendedHeaderSize >= m_tagSize) {
                        setState(ID3_Parser_State_Not_Valid_Tag);
                        enoughBytesToParse = false;
                        break;
                    }
                    
                    ID3_TRACE("Skipping extended header, size %i\n", extendedHeaderSize);
                    
                    pos += extendedHeaderSize;
                }
                
                while (pos < m_tagSize) {
                    char frameName[5];
                    frameName[0] = m_tagData[pos];
                    frameName[1] = m_tagData[pos+1];
                    frameName[2] = m_tagData[pos+2];
                    
                    if (m_majorVersion >= 3) {
                        frameName[3] = m_tagData[pos+3];
                    } else {
                        frameName[3] = 0;
                    }
                    frameName[4] = 0;
                    
                    UInt32 framesize = 0;
                    
                    if (m_majorVersion >= 3) {
                        pos += 4;
                        
                        framesize = ((m_tagData[pos] << 21) |
                                        (m_tagData[pos+1] << 14) |
                                        (m_tagData[pos+2] << 7) |
                                        m_tagData[pos+3]);
                    } else {
                        pos += 3;
                        
                        framesize = ((m_tagData[pos] << 16) |
                                     (m_tagData[pos+1] << 8) |
                                     m_tagData[pos+2]);
                    }
                    
                    if (framesize == 0) {
                        setState(ID3_Parser_State_Not_Valid_Tag);
                        enoughBytesToParse = false;
                        // Break from the loop and then out of the case context
                        goto ParseFramesExit;
                    }
                    
                    if (m_majorVersion >= 3) {
                        pos += 6;
                    } else {
                        pos += 3;
                    }
                    
                    CFStringEncoding encoding;
                    bool byteOrderMark = false;
                    
                    if (m_tagData[pos] == 3) {
                        encoding = kCFStringEncodingUTF8;
                    } else if (m_tagData[pos] == 2) {
                        encoding = kCFStringEncodingUTF16BE;
                    } else if (m_tagData[pos] == 1) {
                        encoding = kCFStringEncodingUTF16;
                        byteOrderMark = true;
                    } else {
                        // ISO-8859-1 is the default encoding
                        encoding = kCFStringEncodingISOLatin1;
                    }
                    
                    if (!strcmp(frameName, "TIT2") || !strcmp(frameName, "TT2")) {
                        if (m_title) {
                            CFRelease(m_title);
                        }
                        m_title = parseContent(framesize, pos + 1, encoding, byteOrderMark);
                        
                        ID3_TRACE("ID3 title parsed: '%s'\n", CFStringGetCStringPtr(m_title, CFStringGetSystemEncoding()));
                    } else if (!strcmp(frameName, "TPE1") || !strcmp(frameName, "TP1")) {
                        if (m_performer) {
                            CFRelease(m_performer);
                        }
                        m_performer = parseContent(framesize, pos + 1, encoding, byteOrderMark);
                        
                        ID3_TRACE("ID3 performer parsed: '%s'\n", CFStringGetCStringPtr(m_performer, CFStringGetSystemEncoding()));
                    } else if (!strcmp(frameName, "APIC")) {
                        char imageType[65] = {0};
                        
                        size_t dataPos = pos+1;
                        
                        for (int i=0; m_tagData[dataPos]; i++,dataPos++) {
                            imageType[i] = m_tagData[dataPos];
                        }
                        dataPos++;
                        
                        if (!strcmp(imageType, "image/jpeg") ||
                            !strcmp(imageType, "image/png")) {
                            
                            ID3_TRACE("Image type %s, parsing, dataPos %zu\n", imageType, dataPos);
                            
                            // Skip the image description
                            while (!m_tagData[++dataPos]);
                            
                            const size_t coverArtSize = framesize - ((dataPos - pos) + 5);
                            
                            UInt8 *bytes = new UInt8[coverArtSize];
                            
                            for (int i=0; i < coverArtSize; i++) {
                                bytes[i] = m_tagData[dataPos+i];
                            }
                            
                            if (m_coverArt) {
                                CFRelease(m_coverArt);
                            }
                            m_coverArt = createBase64EncodedString(bytes, coverArtSize, 0);
                            
                            delete [] bytes;
                        } else {
                            ID3_TRACE("%s is an unknown type for image data, skipping\n", imageType);
                        }
                    } else {
                        // Unknown/unhandled frame
                        ID3_TRACE("Unknown/unhandled frame: %s, size %i\n", frameName, framesize);
                    }
                    
                    pos += framesize;
                }
                
                // Push out the metadata
                if (m_parser->m_delegate) {
                    std::map<CFStringRef,CFStringRef> metadataMap;
                    
                    if (m_performer && CFStringGetLength(m_performer) > 0) {
                        metadataMap[CFSTR("MPMediaItemPropertyArtist")] =
                            CFStringCreateCopy(kCFAllocatorDefault, m_performer);
                    }
                    
                    if (m_title && CFStringGetLength(m_title) > 0) {
                        metadataMap[CFSTR("MPMediaItemPropertyTitle")] =
                            CFStringCreateCopy(kCFAllocatorDefault, m_title);
                    }
                    
                    if (m_coverArt && CFStringGetLength(m_coverArt) > 0) {
                        metadataMap[CFSTR("CoverArt")] =
                            CFStringCreateCopy(kCFAllocatorDefault, m_coverArt);
                    }
                    
                    m_parser->m_delegate->id3metaDataAvailable(metadataMap);
                }
                
                setState(ID3_Parser_State_Tag_Parsed);
                enoughBytesToParse = false;
ParseFramesExit:
                break;
            }
                
            default:
                enoughBytesToParse = false;
                break;
        }
    }
}

void ID3_Parser_Private::setState(astreamer::ID3_Parser_State state)
{
    m_state = state;
}
    
void ID3_Parser_Private::reset()
{
    m_state = ID3_Parser_State_Initial;
    m_bytesReceived = 0;
    m_tagSize = 0;
    m_majorVersion = 0;
    m_hasFooter = false;
    m_usesUnsynchronisation = false;
    m_usesExtendedHeader = false;
    
    if (m_title) {
        CFRelease(m_title), m_title = NULL;
    }
    if (m_performer) {
        CFRelease(m_performer), m_performer = NULL;
    }
    if (m_coverArt) {
        CFRelease(m_coverArt), m_coverArt = NULL;
    }
    
    m_tagData.clear();
}
    
CFStringRef ID3_Parser_Private::parseContent(UInt32 framesize, UInt32 pos, CFStringEncoding encoding, bool byteOrderMark)
{
    CFStringRef content = CFStringCreateWithBytes(kCFAllocatorDefault,
                                                  &m_tagData[pos],
                                                  framesize - 1,
                                                  encoding,
                                                  byteOrderMark);
    
    return content;
}
    
/*
 * =======================================
 * ID3_Parser implementation
 * =======================================
 */
    
ID3_Parser::ID3_Parser() :
    m_delegate(0),
    m_private(new ID3_Parser_Private())
{
    m_private->m_parser = this;
}

ID3_Parser::~ID3_Parser()
{
    delete m_private, m_private = 0;
}

void ID3_Parser::reset()
{
    m_private->reset();
}

bool ID3_Parser::wantData()
{
    return m_private->wantData();
}
    
void ID3_Parser::feedData(UInt8 *data, UInt32 numBytes)
{
    m_private->feedData(data, numBytes);
}
    
}