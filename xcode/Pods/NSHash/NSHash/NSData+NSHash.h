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

@interface NSData (NSHash_AdditionalHashingAlgorithms)

/**
 Creates a MD5 hash of the current NSData object as NSData representation.
 */
- (nonnull NSData*) MD5;

/**
 Creates a MD5 hash of the current NSData object as hex NSString representation.
 */
- (nonnull NSString*) MD5String;

/**
 Creates a SHA1 hash of the current NSData object as NSData representation.
 */
- (nonnull NSData*) SHA1;

/**
 Creates a SHA1 hash of the current NSData object as hex NSString representation.
 */
- (nonnull NSString*) SHA1String;

/**
 Creates a SHA256 hash of the current NSData object as NSData representation.
 */
- (nonnull NSData*) SHA256;

/**
 Creates a SHA256 hash of the current NSData object as hex NSString representation.
 */
- (nonnull NSString*) SHA256String;

@end
