//
//  JasonHelper.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <SBJson/SBJson4Writer.h>
#import "UICKeyChainStore.h"
#import "JasonParser.h"
@interface JasonHelper : NSObject
+ (NSDate *)dateWithISO8601String:(NSString *)dateString;
+ (NSDate *)dateFromString:(NSString *)dateString withFormat:(NSString *)dateFormat;
+ (MFMessageComposeViewController *)sendSMS:(NSString*)message to:(NSString *)phone;
+ (UIColor *)darkerColorForColor:(UIColor *)c;
+ (UIColor *)lighterColorForColor:(UIColor *)c;
+ (BOOL)isColorTranslucent: (NSString *)str;
+ (UIColor *)colorwithHexString:(NSString *)hexStr alpha:(CGFloat)alpha;
+ (NSString *)hexStringFromColor:(UIColor *)color;
+ (NSObject *)cleanNull: (NSObject *)obj type: (NSString *)type;
+ (NSObject *)clean: (NSObject *)obj;
+ (UIImage *)scaleImage: (UIImage *)image ToSize:(CGSize)newSize;
+ (NSString *)mimeTypeForData:(NSData *)data;
+ (UIImage*)colorize: (UIImage *)image into:(UIColor*)color;
+ (NSString*)getParamValueFor:(NSString *)key fromUrl: (NSString *)url;
+ (NSString *)stringify:(id)value;
+ (id)objectify:(NSString*)str;
+ (NSDictionary *)sessionForUrl:(NSString *)url;
+ (NSDictionary*)dictFromJSONFile:(NSString*)filename;
+ (NSDictionary *)jasonify:(NSString*)str;
+ (NSString *)linkify: (NSString *)url;
+ (NSString *)prependProtocolToUrl: (NSString *)url;
+ (void)setStatusBarBackgroundColor:(UIColor *)color;
+ (id)parse: (id)data ofType: (NSString *)type with: (id)template;
+ (id)parse: (id)data with: (id)template;
+ (BOOL)isURL:(NSURL*)url equivalentTo:(NSString *)urlString;
+ (CGFloat)pixelsInDirection: (NSString *)direction fromExpression: (NSString *)expression;
+ (UIImage *)takescreenshot;
+ (NSString*) UTF8StringFromData:(NSData*)data;
+ (NSString *)getSignature: (NSDictionary *)item;
+ (NSArray *)childOf: (UIView *)view withClassName: (NSString *)className;
+ (id) read_local_json: (NSString *)url;
+ (NSString *)normalized_url: (NSString *)url forOptions: (id)options;
+ (CGFloat)parseRatio: (NSString *) ratio;
@end
