/*
 Copyright (c) 2010-2013, Stig Brautaset.
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
#import "SBJson5StreamParser.h"

/**
 Block called when the parser has parsed an item. This could be once
 for each root document parsed, or once for each unwrapped root array element.

 @param item contains the parsed item.
 @param stop set to YES if you want the parser to stop
 */
typedef void (^SBJson5ValueBlock)(id item, BOOL* stop);

/**
 Block called if an error occurs.
 @param error the error.
 */
typedef void (^SBJson5ErrorBlock)(NSError* error);


/**
 Parse one or more chunks of JSON data.

 Using this class directly you can reduce the apparent latency for each
 download/parse cycle of documents over a slow connection. You can start
 parsing *and return chunks of the parsed document* before the entire
 document is downloaded.

 Using this class is also useful to parse huge documents on disk
 bit by bit so you don't have to keep them all in memory.

 ## How JSON is mapped

 JSON is mapped to Objective-C types in the following way:

 - null    -> NSNull
 - string  -> NSString
 - array   -> NSMutableArray
 - object  -> NSMutableDictionary
 - true    -> NSNumber's -numberWithBool:YES
 - false   -> NSNumber's -numberWithBool:NO
 - number -> NSNumber

 Since Objective-C doesn't have a dedicated class for boolean values,
 these turns into NSNumber instances. However, since these are
 initialised with the -initWithBool: method they round-trip back to JSON
 properly. In other words, they won't silently suddenly become 0 or 1;
 they'll be represented as 'true' and 'false' again.

 Integers are parsed into either a `long long` or `unsigned long long`
 type if they fit, else a `double` is used. All real & exponential numbers
 are represented using a `double`. Previous versions of this library used
 an NSDecimalNumber in some cases, but this is no longer the case.

 ## A word of warning

 Stream based parsing does mean that you lose some of the correctness
 verification you would have with a parser that considered the entire input
 before returning an answer. It is technically possible to have some parts
 of a document returned *as if they were correct* but then encounter an error
 in a later part of the document. You should keep this in mind when
 considering whether it would suit your application.

*/
@interface SBJson5Parser : NSObject

/**
 Create a JSON Parser

 This can be used to create a parser that accepts only one document, or one
 that parses many documents, or both! You can also use this if you need to
 parse documents with nesting depth deeper than 32.

 @param block Called for each element. Set *stop to `YES` if you have seen
 enough and would like to skip the rest of the elements.

 @param allowMultiRoot Indicate that you are expecting multiple whitespace-separated
 JSON documents, similar to what Twitter uses.

 @param unwrapRootArray If set the parser will pretend an root array does not exist
 and the enumerator block will be called once for each item in it. This option
 does nothing if the the JSON has an object at its root.

 @param maxDepth The max recursion depth.

 @param eh Called if the parser encounters an error.

 */
+ (id)parserWithBlock:(SBJson5ValueBlock)block
       allowMultiRoot:(BOOL)allowMultiRoot
      unwrapRootArray:(BOOL)unwrapRootArray
             maxDepth:(NSUInteger)maxDepth
         errorHandler:(SBJson5ErrorBlock)eh;

/**
 Create a JSON Parser to parse a single document

 @param block Called for each element. Set *stop to `YES` if you have seen
 enough and would like to skip the rest of the elements.

 @param eh Called if the parser encounters an error.

 */
+ (id)parserWithBlock:(SBJson5ValueBlock)block
         errorHandler:(SBJson5ErrorBlock)eh;


/**
  Create a JSON Parser that parses multiple consequtive documents

 This is useful for something like Twitter's feed, which gives you one JSON
 document per line. Here is an example of parsing many consequtive JSON
 documents, where your block will be called once for each document:

    SBJson5ValueBlock block = ^(id v, BOOL *stop) {
        BOOL isArray = [v isKindOfClass:[NSArray class]];
        NSLog(@"Found: %@", isArray ? @"Array" : @"Object");
    };

    SBJson5ErrorBlock eh = ^(NSError* err) {
        NSLog(@"OOPS: %@", err);
    };

    id parser = [SBJson5Parser multiRootParserWithBlock:block
                                           errorHandler:eh];

    // Note that this input contains multiple top-level JSON documents
    id data = [@"[]{}" dataWithEncoding:NSUTF8StringEncoding];
    [parser parse:data];
    [parser parse:data];

 The above example will print:

 - Found: Array
 - Found: Object
 - Found: Array
 - Found: Object

 @param block Called for each element. Set *stop to `YES` if you have seen
 enough and would like to skip the rest of the elements.

 @param eh Called if the parser encounters an error.

 @see +unwrapRootArrayParserWithBlock:errorHandler:
 @see +parserWithBlock:allowMultiRoot:unwrapRootArray:maxDepth:errorHandler:
 */
+ (id)multiRootParserWithBlock:(SBJson5ValueBlock)block
                  errorHandler:(SBJson5ErrorBlock)eh;

/**
 Create a parser that "unwraps" a top-level array.

 Often you won't have control over the input, so can't use a multi-root
 parser. But, all is not lost: if you are parsing a long array you can get the
 same effect by unwrapping the root array. Here is an example:

    SBJson5ValueBlock block = ^(id v, BOOL *stop) {
        BOOL isArray = [v isKindOfClass:[NSArray class]];
        NSLog(@"Found: %@", isArray ? @"Array" : @"Object");
    };

    SBJson5ErrorBlock eh = ^(NSError* err) {
        NSLog(@"OOPS: %@", err);
    };

    id parser = [SBJson5Parser unwrapRootArrayParserWithBlock:block
                                                 errorHandler:eh];

    // Note that this input contains A SINGLE top-level document
    id data = [@"[[],{},[],{}]" dataWithEncoding:NSUTF8StringEncoding];
    [parser parse:data];

 The above example will print:

 - Found: Array
 - Found: Object
 - Found: Array
 - Found: Object

 @param block Called for each element. Set *stop to `YES` if you have seen
 enough and would like to skip the rest of the elements.

 @param eh Called if the parser encounters an error.

 @see +multiRootParserWithBlock:errorHandler:
 @see +parserWithBlock:allowMultiRoot:unwrapRootArray:maxDepth:errorHandler:
 */
+ (id)unwrapRootArrayParserWithBlock:(SBJson5ValueBlock)block
                        errorHandler:(SBJson5ErrorBlock)eh;

/**
 Feed data to parser

 The JSON is assumed to be UTF8 encoded. This can be a full JSON document, or
 a part of one.

 @param data An NSData object containing the next chunk of JSON

 @return
 - SBJson5ParserComplete if a full document was found
 - SBJson5ParserWaitingForData if a partial document was found and more data is required to complete it
 - SBJson5ParserError if an error occurred.

 */
- (SBJson5ParserStatus)parse:(NSData*)data;

@end
