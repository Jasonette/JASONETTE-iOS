//
//  Created by Matt Gallagher on 2009/06/03.
//  Copyright 2009-2010Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <Foundation/Foundation.h>

/** Low level decoding of base 64 byte arrays
 @param inputBuffer Pointer to a char array where the data to be decoded resides
 @param length Length of inputBuffer array
 @param outputLength Address of variable to write in length of decoded array
 @return void* to an array containing the decoded data
 */
void *UA_NewBase64Decode(
    const char *inputBuffer,
    size_t length,
    size_t *outputLength);

/** Low level encoding of base 64 byte arrays from an input array
 @param inputBuffer Pointer to a char array, or any arbitrary array of Byte size data
 @param length Length of input buffer
 @param separateLines Whether to separate lines of text during encoding
 @param outputLength Pointer to variable where length of returned array will reside
 @return pointer to an array of converted data
 */
char *UA_NewBase64Encode(
    const void *inputBuffer,
    size_t length,
    bool separateLines,
    size_t *outputLength);

/** Returns an NSData object of decoded 64 bit values,
 could be turned into a byte array, or directly into a NSString 
 @param aString base 64 encoded NSString that needs to be decoded
 @return NSData object containing decoded data which can be converted 
 to a byte array or NSString, uses NSASCIIStringEncoding 
 */
NSData* UA_dataFromBase64String(NSString* aString);

/** Takes a byte array filled with ASCII encoded representation
 of data, for our purposes this is a NSString of the app key or 
 secret converted to an NSData object
 @param data NSData representation of a string that needs to be converted
    to base 64 encoding, expects NSASCIIStringEncoding
 @return NSString, base 64 encoded using NSASCIIStringEncoding
 */
NSString* UA_base64EncodedStringFromData(NSData* data);
