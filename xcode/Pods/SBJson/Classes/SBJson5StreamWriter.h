/*
 Copyright (c) 2010, Stig Brautaset.
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:

   Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

   Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

   Neither the name of the the author nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

/// Enable JSON writing for non-native objects
@interface NSObject (SBProxyForJson)

/**
 Allows generation of JSON for otherwise unsupported classes.

 If you have a custom class that you want to create a JSON representation
 for you can implement this method in your class. It should return a
 representation of your object defined in terms of objects that can be
 translated into JSON. For example, a Person object might implement it like this:

     - (id)proxyForJson {
        return [NSDictionary dictionaryWithObjectsAndKeys:
        name, @"name",
        phone, @"phone",
        email, @"email",
        nil];
     }

 */
- (id)proxyForJson;

@end

@class SBJson5StreamWriter;

@protocol SBJson5StreamWriterDelegate

- (void)writer:(SBJson5StreamWriter *)writer appendBytes:(const void *)bytes length:(NSUInteger)length;

@end

@class SBJson5StreamWriterState;

/**
 The Stream Writer class.

 Accepts a stream of messages and writes JSON of these to its delegate object.

 This class provides a range of high-, mid- and low-level methods. You can mix
 and match calls to these. For example, you may want to call -writeArrayOpen
 to start an array and then repeatedly call -writeObject: with various objects
 before finishing off with a -writeArrayClose call.

 Objective-C types are mapped to JSON types in the following way:

 - NSNull        -> null
 - NSString      -> string
 - NSArray       -> array
 - NSDictionary  -> object
 - NSNumber's -initWithBool:YES -> true
 - NSNumber's -initWithBool:NO  -> false
 - NSNumber      -> number

 NSNumber instances created with the -numberWithBool: method are
 converted into the JSON boolean "true" and "false" values, and vice
 versa. Any other NSNumber instances are converted to a JSON number the
 way you would expect.

 @warning: In JSON the keys of an object must be strings. NSDictionary
 keys need not be, but attempting to convert an NSDictionary with
 non-string keys into JSON will throw an exception.*

 */

@interface SBJson5StreamWriter : NSObject {
    NSMutableDictionary *cache;
}

@property (nonatomic, weak) SBJson5StreamWriterState *state; // Internal
@property (nonatomic, readonly, strong) NSMutableArray *stateStack; // Internal

/**
 Create a JSON stream writer

 @param delegate Delegate that will receive messages with output.

 @param maxDepth If the input is nested deeper than this the input will be
 deemed to be malicious and the parser returns nil, signalling an error.
 ("Nested too deep".) You can turn off this security feature by setting the
 maxDepth to 0.

 @param humanReadable If YES, produces human-readable output with linebreaks
 and indentation.

 @param sortKeys Whether or not to sort the dictionary keys in the output.
 (Useful if you need to compare two structures.)

 @param sortKeysComparator A custom comparator to sort dictionary keys when @p
 sortKeys is YES. If nil, @selector(compare:) is used for sorting.

 */

+ (id)writerWithDelegate:(id<SBJson5StreamWriterDelegate>)delegate
                maxDepth:(NSUInteger)maxDepth
           humanReadable:(BOOL)humanReadable
                sortKeys:(BOOL)sortKeys
      sortKeysComparator:(NSComparator)sortKeysComparator;

/// Contains the error description after an error has occurred.
@property (nonatomic, copy) NSString *error;

/**
 Write an NSDictionary to the JSON stream.
 @return YES if successful, or NO on failure
 */
- (BOOL)writeObject:(NSDictionary*)dict;

/**
 Write an NSArray to the JSON stream.
 @return YES if successful, or NO on failure
 */
- (BOOL)writeArray:(NSArray *)array;

/**
 Start writing an Object to the stream
 @return YES if successful, or NO on failure
*/
- (BOOL)writeObjectOpen;

/**
 Close the current object being written
 @return YES if successful, or NO on failure
*/
- (BOOL)writeObjectClose;

/** Start writing an Array to the stream
 @return YES if successful, or NO on failure
*/
- (BOOL)writeArrayOpen;

/** Close the current Array being written
 @return YES if successful, or NO on failure
*/
- (BOOL)writeArrayClose;

/** Write a null to the stream
 @return YES if successful, or NO on failure
*/
- (BOOL)writeNull;

/** Write a boolean to the stream
 @return YES if successful, or NO on failure
*/
- (BOOL)writeBool:(BOOL)x;

/** Write a Number to the stream
 @return YES if successful, or NO on failure
*/
- (BOOL)writeNumber:(NSNumber*)n;

/** Write a String to the stream
 @return YES if successful, or NO on failure
*/
- (BOOL)writeString:(NSString*)s;

@end

@interface SBJson5StreamWriter (Private)
- (BOOL)writeValue:(id)v;
- (void)appendBytes:(const void *)bytes length:(NSUInteger)length;
@end

