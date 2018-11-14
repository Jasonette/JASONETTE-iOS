/* Copyright 2017 Urban Airship and Contributors */

#import <zlib.h>

#import "UARequest+Internal.h"
#import "UAirship.h"
#import "UADisposable.h"
#import "UAConfig.h"
#import "UADelayOperation+Internal.h"

@interface UARequestBuilder()
@property (nonatomic, strong) NSMutableDictionary *headers;
@end
@implementation UARequestBuilder

- (instancetype)init {
    self = [super init];

    if (self) {
        self.headers = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)setValue:(id)value forHeader:(NSString *)header {
    [self.headers setValue:value forKey:header];
}

@end

@interface UARequest()
@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, copy) NSDictionary *headers;
@property (nonatomic, copy, nullable) NSData *body;
@end

@implementation UARequest

- (instancetype)initWithBuilder:(UARequestBuilder *)builder {
    self = [super init];

    if (self) {
        self.method = builder.method;
        self.URL = builder.URL;


        NSMutableDictionary *headers = [NSMutableDictionary dictionary];

        // Basic auth
        if (builder.username && builder.password) {
            NSString *credentials = [NSString stringWithFormat:@"%@:%@", builder.username, builder.password];
            NSData *encodedCredentials = [credentials dataUsingEncoding:NSUTF8StringEncoding];
            NSString *authoriazationValue = [NSString stringWithFormat: @"Basic %@",[encodedCredentials base64EncodedStringWithOptions:0]];
            [headers setValue:authoriazationValue forKey:@"Authorization"];
        }

        // Additional headers
        if (builder.headers) {
            [headers addEntriesFromDictionary:builder.headers];
        }

        if (builder.body) {
            if (builder.compressBody) {
                self.body = [UARequest gzipCompress:builder.body];
                headers[@"Content-Encoding"] = @"gzip";
            } else {
                self.body = builder.body;
            }
        }


        self.headers = headers;
    }

    return self;
}

+ (instancetype)requestWithBuilderBlock:(void(^)(UARequestBuilder *builder))builderBlock {
    UARequestBuilder *builder = [[UARequestBuilder alloc] init];
    builder.compressBody = NO;

    if (builderBlock) {
        builderBlock(builder);
    }

    return [[UARequest alloc] initWithBuilder:builder];
}

+ (NSData *)gzipCompress:(NSData *)uncompressedData {

    if ([uncompressedData length] == 0) {
        return nil;
    }

    z_stream strm;

    NSUInteger chunkSize = 32768;// 32K chunks

    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *)[uncompressedData bytes];
    strm.avail_in = (uInt)[uncompressedData length];

    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) {
        return nil;
    }

    int status;
    NSMutableData *compressed = [NSMutableData dataWithLength:chunkSize];
    do {

        if (strm.total_out >= [compressed length]) {
            [compressed increaseLengthBy:chunkSize];
        }

        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([compressed length] - strm.total_out);

        status = deflate(&strm, Z_FINISH);

        if (status == Z_STREAM_ERROR) {
            //error - bail completely
            deflateEnd(&strm);
            return nil;
        }

    } while (strm.avail_out == 0);

    deflateEnd(&strm);

    [compressed setLength: strm.total_out];
    
    return compressed;
}

@end
