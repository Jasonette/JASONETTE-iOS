//
//  Copyright 2012-2015 Christoph Jerolimov
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License
//

#import <Foundation/Foundation.h>

@interface NSString (NSHash_AdditionalHashingAlgorithms)

/**
 Creates a MD5 hash of the current string as hex NSString representation.
 */
- (nonnull NSString*) MD5;

/**
 Creates a MD5 hash of the current string as NSData representation.
 */
- (nonnull NSData*) MD5Data;

/**
 Creates a SHA1 hash of the current string as hex NSString representation.
 */
- (nonnull NSString*) SHA1;

/**
 Creates a SHA1 hash of the current string as NSData representation.
 */
- (nonnull NSData*) SHA1Data;

/**
 Creates a SHA256 hash of the current string as hex NSString representation.
 */
- (nonnull NSString*) SHA256;

/**
 Creates a SHA256 hash of the current string as NSData representation.
 */
- (nonnull NSData*) SHA256Data;

@end
