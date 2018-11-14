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
#import <MobileCoreServices/MobileCoreServices.h>

#import "UAMediaAttachmentExtension.h"
#import "UAMediaAttachmentPayload.h"

#define kUANotificationAttachmentServiceMediaAttachmentKey @"com.urbanairship.media_attachment"

@interface UAMediaAttachmentExtension ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;
@property (nonatomic, strong) UNMutableNotificationContent *modifiedContent;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@end

@implementation UAMediaAttachmentExtension

- (NSURL *)processTempFile:(NSURL *)tempFileURL originalURL:originalURL {

    // Affix the original filename, as the temp file will be lacking a file type
    NSString *suffix = [NSString stringWithFormat:@"-%@", [originalURL lastPathComponent]];
    NSURL *destinationURL = [NSURL fileURLWithPath:[tempFileURL.path stringByAppendingString:suffix]];

    NSFileManager *fm = [NSFileManager defaultManager];

    // Remove anything currently existing at the destination path
    if ([fm fileExistsAtPath:destinationURL.path]) {
        NSError *error;
        [fm removeItemAtPath:destinationURL.path error:&error];

        if (error) {
            NSLog(@"Error removing file %@: %@", destinationURL.path, error.localizedDescription);
        }
    }

    // Rename temp file
    NSError *error;
    [fm moveItemAtURL:tempFileURL toURL:destinationURL error:&error];

    if (error) {
        NSLog(@"Error copying file at %@ to %@: %@", tempFileURL.path, destinationURL.path, error.localizedDescription);
    }

    return destinationURL;
}

- (NSDictionary *)uniformTypeIdentifierMap {

    // Offset 0
    uint8_t jpeg[] = {0xFF, 0xD8, 0xFF, 0xE0};
    uint8_t jpegAlt[] = {0xFF, 0xD8, 0xFF, 0xE2};
    uint8_t jpegAlt2[] = {0xFF, 0xD8, 0xFF, 0xE3};
    uint8_t png[] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
    uint8_t gif[] = {0x47, 0x49, 0x46, 0x38};
    uint8_t aiff[] = {0x46, 0x4F, 0x52, 0x4D, 0x00};
    uint8_t mp3[] = {0x49, 0x44, 0x33};
    uint8_t mpeg[] = {0x00, 0x00, 0x01, 0xBA};
    uint8_t mpegAlt[] = {0x00, 0x00, 0x01, 0xB3};

    // Offset 4
    uint8_t mp4v1[] = {0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x31};
    uint8_t mp4v2[] = {0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32};
    uint8_t mp4mmp4[] = {0x66, 0x74, 0x79, 0x70, 0x6D, 0x6D, 0x70, 0x34};
    uint8_t mp4isom[] = {0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6f, 0x6d};
    uint8_t m4a[] = {0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41, 0x20};

    // Offset 8
    uint8_t wav[] = {0x57, 0x41, 0x56, 0x45};
    uint8_t avi[] = {0x41, 0x56, 0x49, 0x20};

    // Convenience block for building signature info
    NSDictionary * (^sig)(NSUInteger, uint8_t *, NSUInteger) = ^NSDictionary *(NSUInteger offset, uint8_t *bytes, NSUInteger length) {
        NSData *data = [NSData dataWithBytes:bytes length:length];
        return @{@"offset" : @(offset), @"length": @(length), @"bytes":data};
    };

    // Known type identifiers and their respective signatures
    NSDictionary *types = @{@"public.jpeg" : @[sig(0, jpeg, sizeof(jpeg)), sig(0, jpegAlt, sizeof(jpegAlt)), sig(0, jpegAlt2, sizeof(jpegAlt2))],
                            @"public.png" : @[sig(0, png, sizeof(png))],
                            @"com.compuserve.gif" : @[sig(0, gif, sizeof(gif))],
                            @"public.aiff-audio" : @[sig(0, aiff, sizeof(aiff))],
                            @"com.microsoft.waveform-audio" : @[sig(8, wav, sizeof(wav))],
                            @"public.avi" : @[sig(8, avi, sizeof(avi))],
                            @"public.mp3" : @[sig(0, mp3, sizeof(mp3))],
                            @"public.mpeg-4" : @[sig(4, mp4v1, sizeof(mp4v1)), sig(4, mp4v2, sizeof(mp4v2)), sig(4, mp4mmp4, sizeof(mp4mmp4)), sig(4, mp4isom, sizeof(mp4isom))],
                            @"public.mpeg-4-audio" : @[sig(4, m4a, sizeof(m4a))],
                            @"public.mpeg" : @[sig(0, mpeg, sizeof(mpeg)), sig(0, mpegAlt, sizeof(mpegAlt))]};

    return types;
}

- (NSString *)uniformTypeIdentifierForData:(NSData *)data {

    // Grab the first 16 bytes
    NSUInteger length = 16;

    if (data.length < length) {
        return nil;
    }

    uint8_t header[length];
    [data getBytes:&header length:length];

    // Compare against known type signatures
    NSDictionary *types = [self uniformTypeIdentifierMap];

    for (NSString *typeIdentifier in types) {
        NSArray *signatures = types[typeIdentifier];
        for (NSDictionary *signature in signatures) {
            NSUInteger offset = [signature[@"offset"] unsignedIntegerValue];
            NSUInteger signatureLength = [signature[@"length"] unsignedIntegerValue];
            NSData *bytes = signature[@"bytes"];

            if (memcmp(header + offset, bytes.bytes, signatureLength) == 0) {
                return typeIdentifier;
            }
        }
    }

    NSLog(@"Unable to infer type identifier for header: %@", [NSData dataWithBytes:header length:length]);

    return nil;
}

- (UNNotificationAttachment *)attachmentWithTemporaryFileLocation:(NSURL *)location
                                                      originalURL:originalURL
                                                         mimeType:(NSString *)mimeType
                                                          options:(NSDictionary *)options
                                                       identifier:(NSString *)identifier {

    NSURL *fileURL = [self processTempFile:location originalURL:originalURL];

    if (!fileURL) {
        return nil;
    }

    NSArray *knownExtensions = @[@"jpg", @"jpeg", @"png", @"gif", @"aif", @"aiff", @"mp3",
                                 @"mpg", @"mpeg", @"mp4", @"m4a", @"wav", @"avi"];
    BOOL hasExtension = NO;
    for (NSString *extension in knownExtensions) {
        if ([[fileURL.lastPathComponent lowercaseString] hasSuffix:extension]) {
            hasExtension = YES;
        }
    }

    // No extension, try to determine the type
    if (!hasExtension) {
        NSString *inferredTypeIdentifier = nil;

        // First try the mimetype if its available
        if (mimeType) {
            CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)mimeType, NULL);

            CFStringRef acceptedTypes[] = { kUTTypeAudioInterchangeFileFormat, kUTTypeWaveformAudio,
                kUTTypeMP3, kUTTypeMPEG4Audio, kUTTypeJPEG, kUTTypeGIF, kUTTypePNG, kUTTypeMPEG,
                kUTTypeMPEG2Video, kUTTypeMPEG4, kUTTypeAVIMovie };


            for (int i = 0; i < 11; i++) {
                if (UTTypeConformsTo(uti, acceptedTypes[i])) {
                    inferredTypeIdentifier = (__bridge_transfer NSString *)uti;
                    break;
                }
            }
        }

        // Fallback to file header inspection
        if (!inferredTypeIdentifier.length) {
            // Note: NSMappedRead will page in the data as it's read, so we don't load the whole file into memory
            NSData *fileData = [NSData dataWithContentsOfFile:fileURL.path
                                                      options:NSMappedRead
                                                        error:nil];
            inferredTypeIdentifier = [self uniformTypeIdentifierForData:fileData];
        }

        if (inferredTypeIdentifier) {
            NSLog(@"Inferred type identifier: %@", inferredTypeIdentifier);
            options = [NSMutableDictionary dictionaryWithDictionary:options];
            [options setValue:inferredTypeIdentifier forKey:UNNotificationAttachmentOptionsTypeHintKey];
        }
    }


    NSError *error;
    UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:identifier URL:fileURL options:options error:&error];

    if (error) {
        NSLog(@"Unable to create attachment: %@", error.localizedDescription);
    }

    return attachment;
}

- (NSURLSessionDownloadTask *)downloadTaskWithPayload:(UAMediaAttachmentPayload *)payload {

    // Pass an empty string for the identifier so that the attachment can generate its own unique ID
    NSString *identifier = @"";

    NSURL *url = [payload.urls firstObject];

    return [[NSURLSession sharedSession]
            downloadTaskWithURL:url
            completionHandler:^(NSURL *temporaryFileLocation, NSURLResponse *response, NSError *error) {

                if (error) {
                    NSLog(@"Error downloading attachment: %@", error.localizedDescription);
                    self.contentHandler(self.bestAttemptContent);
                    return;
                }

                NSString *mimeType = nil;
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    mimeType = httpResponse.allHeaderFields[@"Content-Type"];
                }

                UNNotificationAttachment *attachment = [self attachmentWithTemporaryFileLocation:temporaryFileLocation
                                                                                     originalURL:url
                                                                                        mimeType:mimeType
                                                                                         options:payload.options
                                                                                      identifier:identifier];

                // A nil attachment may indicate an unrecognized file type
                if (!attachment) {
                    self.contentHandler(self.bestAttemptContent);
                    return;
                }

                self.modifiedContent.attachments = @[attachment];

                if (payload.content.body) {
                    self.modifiedContent.body = payload.content.body;
                }

                if (payload.content.title) {
                    self.modifiedContent.title = payload.content.title;
                }

                if (payload.content.subtitle) {
                    self.modifiedContent.subtitle = payload.content.subtitle;
                }

                self.contentHandler(self.modifiedContent);
            }];
}

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {

    self.contentHandler = contentHandler;

    self.bestAttemptContent = [request.content mutableCopy];
    self.modifiedContent = [request.content mutableCopy];

    id jsonPayload = request.content.userInfo[kUANotificationAttachmentServiceMediaAttachmentKey];

    if (jsonPayload) {
        UAMediaAttachmentPayload *payload = [UAMediaAttachmentPayload payloadWithJSONObject:jsonPayload];
        if (payload) {
            self.downloadTask = [self downloadTaskWithPayload:payload];
            [self.downloadTask resume];
        } else {
            NSLog(@"Unable to parse attachment: %@", payload);
            self.contentHandler(self.bestAttemptContent);
        }
    } else {
        self.contentHandler(self.bestAttemptContent);
    }
}

- (void)serviceExtensionTimeWillExpire {
    [self.downloadTask cancel];
    self.contentHandler(self.bestAttemptContent);
}

@end
