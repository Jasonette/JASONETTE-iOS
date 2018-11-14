/*
 Copyright 2009-2016 Urban Airship Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

/**
 * Model object for notification content override.
 */
@interface UAMediaAttachmentContent : NSObject

/**
 * The notification body.
 */
@property(nonatomic, readonly) NSString *body;

/**
 * The notification title.
 */
@property(nonatomic, readonly) NSString *title;

/**
 * The notification subtitle
 */
@property(nonatomic, readonly) NSString *subtitle;

@end

/**
 * Model object for the media attachment device payload
 */
@interface UAMediaAttachmentPayload : NSObject

/**
 * Factory method for creating a payload from a JSON object
 */
+ (instancetype)payloadWithJSONObject:(id)object;

/**
 * An array of media attachment URLs.
 */
@property(nonatomic, readonly) NSMutableArray *urls;

/**
 * Attachment options in the dictionary format expected by UNNotificationAttachment
 */
@property(nonatomic, readonly) NSDictionary *options;

/**
 * Optional content override for the modified notification.
 */
@property(nonatomic, readonly) UAMediaAttachmentContent *content;

@end


