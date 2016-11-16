// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSPush.h"
#import "MSPushRequest.h"
#import "MSURLBuilder.h"
#import "MSClientInternal.h"

#pragma mark * MSPushRequest Implementation
@implementation MSPushRequest

#pragma mark * Private Static Constructors
- (MSPushRequest *)initWithURL:(NSURL *)url
                          data:(NSData *)data
                    HTTPMethod:(NSString *)method
{
    // Create the request
    MSPushRequest *request = [[MSPushRequest alloc] initWithURL:url];
    
    // Set the method and headers
    request.HTTPMethod = [method uppercaseString];

    request.HTTPBody = data;
    
    return request;
}

#pragma mark * Private Initializer Method

- (id)initWithURL:(NSURL *)url
{
    self = [super initWithURL:url];
    
    return self;
}

+(MSPushRequest *) requestToRegisterDeviceToken:(NSData *)deviceToken
                                           push:(MSPush *)push
                                      templates:(NSDictionary *)templates
                                     completion:(MSCompletionBlock)completion
{
    NSError *error = nil;
    id<MSSerializer> serializer = push.client.serializer;
    
    NSURL *pushURL = [push.client.applicationURL URLByAppendingPathComponent:@"push/installations"];

    MSPushRequest *request = [MSPushRequest new];
    request.URL = [pushURL URLByAppendingPathComponent:push.client.installId];
    request.HTTPMethod = @"PUT";
    
    NSString *stringDeviceToken = [MSPushRequest deviceTokenAsString:deviceToken];
    
    NSMutableDictionary *fullTemplate = [@{@"pushChannel": stringDeviceToken, @"platform": @"apns" } mutableCopy];
    if (templates) {
        // convert body nodes to strings
        NSMutableDictionary *adjustedTemplates = [templates mutableCopy];
        for(id templateId in adjustedTemplates) {
            if ([adjustedTemplates[templateId] isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *template = [(NSDictionary *)adjustedTemplates[templateId] mutableCopy];
                
                id value = template[@"body"];
                if ([value isKindOfClass:[NSDictionary class]]) {
                    NSData *data = [serializer dataFromItem:value idAllowed:YES ensureDictionary:NO removeSystemProperties:NO orError:&error];
                    if (error) {
                        break;
                    }
                    
                    template[@"body"] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    adjustedTemplates[templateId] = template;
                }
            }
        }
        
        [fullTemplate setValue:adjustedTemplates forKey:@"templates"];
    }
    
    NSData *data = [serializer dataFromItem:fullTemplate idAllowed:YES ensureDictionary:YES removeSystemProperties:NO orError:&error];
    if (error) {
        if (completion) {
            completion(error);
        }
        return nil;
    }
    request.HTTPBody = data;
    
    return request;
}

+(MSPushRequest *) requestToUnregisterPush:(MSPush *)push
                                completion:(MSCompletionBlock)completion
{
    MSPushRequest *request = [[MSPushRequest alloc] init];
    
    NSURL *pushURL = [push.client.applicationURL URLByAppendingPathComponent:@"push/installations"];
    request.URL = [pushURL URLByAppendingPathComponent:push.client.installId];
    
    request.HTTPMethod = @"DELETE";

    return request;
}

/// Converts a NSData representation of a device token into a NSString
+ (NSString *)deviceTokenAsString:(NSData *)deviceTokenData
{
    NSCharacterSet *hexFormattingCharacters = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
    NSString* newDeviceToken = [[[deviceTokenData.description stringByTrimmingCharactersInSet:hexFormattingCharacters]
                                    stringByReplacingOccurrencesOfString:@" " withString:@""]
                                    uppercaseString];
    return newDeviceToken;
}

@end
