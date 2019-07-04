//
//  INTUHeadingRequest.h
//
//  Copyright (c) 2014-2015 Intuit Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "INTULocationRequestDefines.h"

__INTU_ASSUME_NONNULL_BEGIN

@interface INTUHeadingRequest : NSObject

/** The request ID for this heading request (set during initialization). */
@property (nonatomic, readonly) INTUHeadingRequestID requestID;
/** Whether this is a recurring heading request (all heading requests are assumed to be for now). */
@property (nonatomic, readonly) BOOL isRecurring;
/** The block to execute when the heading request completes. */
@property (nonatomic, copy, __INTU_NULLABLE) INTUHeadingRequestBlock block;

@end

__INTU_ASSUME_NONNULL_END