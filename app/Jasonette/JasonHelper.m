//
//  JasonHelper.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonHelper.h"

@implementation JasonHelper
+ (NSDate *)dateWithISO8601String:(NSString *)dateString
{
    if (!dateString || [[NSNull null] isEqual:dateString]) return nil;
    if ([dateString hasSuffix:@"Z"]) {
        dateString = [[dateString substringToIndex:(dateString.length-1)] stringByAppendingString:@"-0000"];
    }
    return [self dateFromString:dateString
                     withFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
}

+ (NSDate *)dateFromString:(NSString *)dateString
                withFormat:(NSString *)dateFormat
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:dateFormat];
    
    NSLocale *locale = [[NSLocale alloc]
                        initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:locale];
    
    NSDate *date = [dateFormatter dateFromString:dateString];
    return date;
}
+ (MFMessageComposeViewController *)sendSMS:(NSString*)message to:(NSString *)phone{
    
    if(![MFMessageComposeViewController canSendText]) {
        return nil;
    }
    
    NSArray *recipents = @[phone];
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    [messageController setRecipients:recipents];
    [messageController setBody:message];
    [messageController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    return messageController;
}
+ (UIColor *)darkerColorForColor:(UIColor *)c
{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.1, 0.0)
                               green:MAX(g - 0.1, 0.0)
                                blue:MAX(b - 0.1, 0.0)
                               alpha:a];
    return nil;
}
+ (UIColor *)lighterColorForColor:(UIColor *)c
{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MIN(r + 0.1, 1.0)
                               green:MIN(g + 0.1, 1.0)
                                blue:MIN(b + 0.1, 1.0)
                               alpha:a];
    return nil;
}
+ (NSString *)hexStringFromColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    
    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)];
}
+ (BOOL)isColorTranslucent: (NSString *)str{
    if([str localizedCaseInsensitiveContainsString:@"rgba("]){
        NSScanner *scanner = [NSScanner scannerWithString:str];
        NSString *junk, *red, *green, *blue, *opacity;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&junk];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet punctuationCharacterSet] intoString:&red];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&junk];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet punctuationCharacterSet] intoString:&green];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&junk];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet punctuationCharacterSet] intoString:&blue];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&junk];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@")"] intoString:&opacity];
        if(opacity.floatValue < 1.0){
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}
+ (UIColor *)colorwithHexString:(NSString *)hexStr alpha:(CGFloat)alpha
{
    
    if([hexStr localizedCaseInsensitiveContainsString:@"rgb("]){
        NSScanner *scanner = [NSScanner scannerWithString:hexStr];
        NSString *junk, *red, *green, *blue;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&junk];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet punctuationCharacterSet] intoString:&red];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&junk];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet punctuationCharacterSet] intoString:&green];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&junk];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet punctuationCharacterSet] intoString:&blue];
        UIColor *color = [UIColor colorWithRed:red.intValue/255.0 green:green.intValue/255.0 blue:blue.intValue/255.0 alpha:1.0];
        return color;
    } else if([hexStr localizedCaseInsensitiveContainsString:@"rgba("]){
        NSScanner *scanner = [NSScanner scannerWithString:hexStr];
        NSString *junk, *red, *green, *blue, *opacity;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&junk];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet punctuationCharacterSet] intoString:&red];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&junk];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet punctuationCharacterSet] intoString:&green];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&junk];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet punctuationCharacterSet] intoString:&blue];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&junk];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@")"] intoString:&opacity];
        UIColor *color = [UIColor colorWithRed:red.intValue/255.0 green:green.intValue/255.0 blue:blue.intValue/255.0 alpha:opacity.floatValue];
        return color;
    } else {
        //-----------------------------------------
        // Convert hex string to an integer
        //-----------------------------------------
        unsigned int hexint = 0;
        
        // Create scanner
        NSScanner *scanner = [NSScanner scannerWithString:hexStr];
        
        // Tell scanner to skip the # character
        [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
        [scanner scanHexInt:&hexint];
        
        //-----------------------------------------
        // Create color object, specifying alpha
        //-----------------------------------------
        UIColor *color = [UIColor colorWithRed:((CGFloat) ((hexint & 0xFF0000) >> 16))/255
                        green:((CGFloat) ((hexint & 0xFF00) >> 8))/255
                         blue:((CGFloat) (hexint & 0xFF))/255
                        alpha:alpha];
        
        return color;
        
    }
    
    
}

+ (NSObject *)cleanNull: (NSObject *)obj type:(NSString*)type{
    if(!obj || [[NSNull null] isEqual:obj]){
        if([type isEqualToString:@"string"]){
            return @"";
        } else if([type isEqualToString:@"number"]){
            return @0;
        } else {
            return nil;
        }
    } else {
        return obj;
    }
}

+ (NSObject *)clean: (NSObject *)obj{
    if(!obj || [[NSNull null] isEqual:obj]){
        return nil;
    } else {
        return obj;
    }
}

+ (UIImage *)scaleImage: (UIImage *)image ToSize:(CGSize)newSize {
    
    CGRect scaledImageRect = CGRectZero;
    
    CGFloat aspectWidth = newSize.width / image.size.width;
    CGFloat aspectHeight = newSize.height / image.size.height;
    CGFloat aspectRatio = MIN ( aspectWidth, aspectHeight );
    
    scaledImageRect.size.width = image.size.width * aspectRatio;
    scaledImageRect.size.height = image.size.height * aspectRatio;
    scaledImageRect.origin.x = (newSize.width - scaledImageRect.size.width) / 2.0f;
    scaledImageRect.origin.y = (newSize.height - scaledImageRect.size.height) / 2.0f;
    
    UIGraphicsBeginImageContextWithOptions( newSize, NO, 0 );
    [image drawInRect:scaledImageRect];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
    
}
+ (id)valueOf: (id) object forKeyPathWithIndexes:(NSString*)fullPath
{
    NSRange testrange = [fullPath rangeOfString:@"["];
    if (testrange.location == NSNotFound)
        return [object valueForKeyPath:fullPath];
    
    NSArray* parts = [fullPath componentsSeparatedByString:@"."];
    id currentObj = object;
    for (NSString* part in parts)
    {
        NSRange range1 = [part rangeOfString:@"["];
        if (range1.location == NSNotFound)
        {
            currentObj = [currentObj valueForKey:part];
        }
        else
        {
            NSString* arrayKey = [part substringToIndex:range1.location];
            int index = [[[part substringToIndex:part.length-1] substringFromIndex:range1.location+1] intValue];
            currentObj = [[currentObj valueForKey:arrayKey] objectAtIndex:index];
        }
    }
    return currentObj;
}
+ (NSString *)mimeTypeForData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
            break;
        case 0x89:
            return @"image/png";
            break;
        case 0x47:
            return @"image/gif";
            break;
        case 0x49:
        case 0x4D:
            return @"image/tiff";
            break;
        case 0x25:
            return @"application/pdf";
            break;
        case 0xD0:
            return @"application/vnd";
            break;
        case 0x46:
            return @"text/plain";
            break;
        default:
            return nil;//@"application/octet-stream";
    }
    return nil;
}


+ (UIImage*)colorize: (UIImage *)image into:(UIColor*)color {
    UIGraphicsBeginImageContextWithOptions(image.size, YES, [[UIScreen mainScreen] scale]);
    
    CGRect contextRect;
    contextRect.origin.x = 0.0f;
    contextRect.origin.y = 0.0f;
    contextRect.size = [image size];
    
    // Retrieve source image and begin image context
    CGSize itemImageSize = [image size];
    CGPoint itemImagePosition;
    itemImagePosition.x = ceilf((contextRect.size.width - itemImageSize.width) / 2);
    itemImagePosition.y = ceilf((contextRect.size.height - itemImageSize.height) );
    
    UIGraphicsBeginImageContextWithOptions(contextRect.size, NO, [[UIScreen mainScreen] scale]);
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    // Setup shadow
    // Setup transparency layer and clip to mask
    CGContextBeginTransparencyLayer(c, NULL);
    CGContextScaleCTM(c, 1.0, -1.0);
    CGContextClipToMask(c, CGRectMake(itemImagePosition.x, -itemImagePosition.y, itemImageSize.width, -itemImageSize.height), [image CGImage]);
    
    // Fill and end the transparency layer
    CGColorSpaceRef colorSpace = CGColorGetColorSpace(color.CGColor);
    CGColorSpaceModel model = CGColorSpaceGetModel(colorSpace);
    const CGFloat* colors = CGColorGetComponents(color.CGColor);
    
    if(model == kCGColorSpaceModelMonochrome) {
        CGContextSetRGBFillColor(c, colors[0], colors[0], colors[0], colors[1]);
    } else {
        CGContextSetRGBFillColor(c, colors[0], colors[1], colors[2], colors[3]);
    }
    contextRect.size.height = -contextRect.size.height;
    contextRect.size.height -= 15;
    CGContextFillRect(c, contextRect);
    CGContextEndTransparencyLayer(c);
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

+ (NSString*)getParamValueFor:(NSString *)key fromUrl: (NSString *)url{
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:[NSURL URLWithString:url] resolvingAgainstBaseURL:NO];
    NSArray *queryItems = urlComponents.queryItems;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
    NSURLQueryItem *queryItem = [[queryItems filteredArrayUsingPredicate:predicate] firstObject];
    return queryItem.value;
}
+ (id)objectify:(NSString *)str{
    NSString *converted = str;
    NSError *error;
    NSData *data = [converted dataUsingEncoding: NSUTF8StringEncoding];
    id result = [NSJSONSerialization JSONObjectWithData: data options: 0 error: &error];
    if (result == nil) {
        NSLog(@"Error: %@", error.localizedDescription);
        return nil;
    }
    return result;
}

+ (NSString *)stringify:(id)value{
    /*
    NSError *error;
    @try {
        NSData *data = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:&error];
        NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return str;
    } @catch (NSException *exception) {
        return @"";
    }
    return @"";
     */
    
    SBJson4Writer *writer = [[SBJson4Writer alloc] init];
//    writer.humanReadable = YES;
    writer.humanReadable = NO;
    writer.sortKeys = YES;
    @try {
        NSString *ret = [writer stringWithObject:value];
        if(ret){
            return ret;
        } else {
            return [value description];
        }
    } @catch(NSException *exception){
        return [value description];
    }
}
+ (NSDictionary *)sessionForUrl:(NSString *)url{
    NSString *domain = [[[NSURL URLWithString:url] host] lowercaseString];
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:domain];
    return [keychain[@"session"] propertyList];
}
+(NSDictionary*)dictFromJSONFile:(NSString*)filename{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    __autoreleasing NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions error:&error];
    // Be careful here. You add this as a category to NSDictionary
    // but you get an id back, which means that result
    // might be an NSArray as well!
    if (error != nil) return nil;
    return result;
}
+ (NSDictionary *)jasonify:(NSString*)str{
    if(!str) return nil;
    if(str.length == 0) return nil;
    
    NSData *webData = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:webData options:0 error:&error];
    if(jsonDict){
        // starts with $jason
        // has head
        // has body
        NSDictionary *res = jsonDict[@"$jason"];
        if(res && res.count > 0){
            return jsonDict;
        }
    }
    return nil;
}
+ (NSString *)linkify: (NSString *)url{
    if(url && url.length > 0){
        url = [url stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if([[url lowercaseString] hasPrefix:@"data:"]){
            url = url;
        }else if ([[url lowercaseString] hasPrefix:@"http://"] || [[url lowercaseString] hasPrefix:@"https://"]) {
            url = url;
        } else if([[url lowercaseString] hasPrefix:@"file://"]){
            url = url;
        } else {
            url = [NSString stringWithFormat:@"http://%@", url];
        }
        url = [url stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet illegalCharacterSet] invertedSet]];

    }
    return url;
}
+ (NSString *)prependProtocolToUrl: (NSString *)url{
    if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) {
        return url;
    } else {
        return [NSString stringWithFormat:@"http://%@", url];
    }
}
+ (void)setStatusBarBackgroundColor:(UIColor *)color {
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
        statusBar.backgroundColor = color;
    }
}
+ (id)parse: (id)data ofType: (NSString *)type with: (id)template{
    if(template){
        id res = [JasonParser parse:data type:type with:template];
        if([res isKindOfClass:[NSArray class]]){
            return (NSArray *)res;
        } else {
            return res;
        }
    } else {
        if(data){
            return data;
        } else {
            return @{};
        }
    }
}
+ (id)parse: (id)data with: (id)template{
    if(template){
        id res = [JasonParser parse:data with:template];
        if([res isKindOfClass:[NSArray class]]){
            return (NSArray *)res;
        } else {
            return res;
        }
    } else {
        if(data){
            return data;
        } else {
            return @{};
        }
    }
}
+ (BOOL)isURL:(NSURL*)url equivalentTo:(NSString *)urlString{
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    urlComponents.query = nil; // Strip out query parameters.
    
    
    NSURLComponents *urlComponents2 = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:urlString] resolvingAgainstBaseURL:NO];
    urlComponents2.query = nil; // Strip out query parameters.
    return [urlComponents.string isEqualToString:urlComponents2.string];
}
+ (CGFloat)parseRatio: (NSString *) ratio {
    if([ratio containsString:@":"] || [ratio containsString:@"/"]) {
        NSError *error = nil;
        NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^[ ]*([0-9]+)[ ]*[:/][ ]*([0-9]+)[ ]*$" options:0 error:&error];
        NSRange searchedRange = NSMakeRange(0, [ratio length]);
        NSTextCheckingResult *match = [regex firstMatchInString:ratio options:0 range: searchedRange];
        if(match){
            NSString *w = [ratio substringWithRange:[match rangeAtIndex:1]];
            NSString *h = [ratio substringWithRange:[match rangeAtIndex:2]];
            return [w floatValue]/[h floatValue];
        } else {
            return 1; // shouldn't happen
        }
    } else {
        return [ratio floatValue];
    }
}
+ (CGFloat)pixelsInDirection: (NSString *)direction fromExpression: (NSString *)expression {
    NSError *error = nil;
    CGFloat full_dimension;
    if(!expression) return 0;
    
    if([direction isEqualToString:@"vertical"]){
        full_dimension = [[UIScreen mainScreen] bounds].size.height;
    } else {
        full_dimension = [[UIScreen mainScreen] bounds].size.width;
    }
    NSRange searchedRange = NSMakeRange(0, [expression length]);
    NSRegularExpression* regexPercentageWithPixels = [NSRegularExpression regularExpressionWithPattern:@"^([0-9.]+)%[ ]*([+-]?)[ ]*([0-9]+)$" options:0 error:&error];
    NSTextCheckingResult *matchPercentageWithPixels = [regexPercentageWithPixels firstMatchInString:expression options:0 range: searchedRange];
    CGFloat dimension;
    if(matchPercentageWithPixels){
        // Percentage +/- Pixels
        // Calculate percentage
        NSString *percentage = [expression substringWithRange:[matchPercentageWithPixels rangeAtIndex:1]];
        dimension = full_dimension * ([percentage floatValue] / 100);
        
        // Get pixels
        NSString *pixels = [expression substringWithRange:[matchPercentageWithPixels rangeAtIndex:3]];
        CGFloat p = [pixels floatValue];
        
        // Determine sign
        NSString *sign = [expression substringWithRange:[matchPercentageWithPixels rangeAtIndex:2]];
        if([sign isEqualToString:@"+"]){
            dimension = dimension + p;
        } else if([sign isEqualToString:@"-"]){
            dimension = dimension - p;
        }
        
    } else {
        
        NSRegularExpression* regexPixels = [NSRegularExpression regularExpressionWithPattern:@"^([0-9.]+)$" options:0 error:&error];
        NSTextCheckingResult *matchPixels = [regexPixels firstMatchInString:expression options:0 range: searchedRange];
        if(matchPixels){
            // Pixels only
            dimension = [expression floatValue];
        } else {
            NSRegularExpression* regexFractionWithPixels = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]+)\\/([0-9]+)[ ]*([+-]?)[ ]*([0-9]+)$" options:0 error:&error];
            NSTextCheckingResult *matchFractionWithPixels = [regexFractionWithPixels firstMatchInString:expression options:0 range: searchedRange];
            if(matchFractionWithPixels){
                // Percetnage +/- Pixels
                NSString *top = [expression substringWithRange:[matchFractionWithPixels rangeAtIndex:1]];
                NSString *bottom = [expression substringWithRange:[matchFractionWithPixels rangeAtIndex:2]];
                
                CGFloat convertedFraction = [top floatValue] / [bottom floatValue];

                dimension = full_dimension * convertedFraction;
                
                // Get pixels
                NSString *pixels = [expression substringWithRange:[matchFractionWithPixels rangeAtIndex:4]];
                CGFloat p = [pixels floatValue];
                
                // Determine sign
                NSString *sign = [expression substringWithRange:[matchFractionWithPixels rangeAtIndex:3]];
                if([sign isEqualToString:@"+"]){
                    dimension = dimension + p;
                } else if([sign isEqualToString:@"-"]){
                    dimension = dimension - p;
                }
                
            } else {
            
                NSRegularExpression* regexPercentage = [NSRegularExpression regularExpressionWithPattern:@"^([0-9.]+)%$" options:0 error:&error];
                NSTextCheckingResult *matchPercentage = [regexPercentage firstMatchInString:expression options:0 range: searchedRange];
                if(matchPercentage){
                    // Percentage only
                    NSString *p = [expression substringWithRange:[matchPercentage rangeAtIndex:1]];
                    dimension = full_dimension * ([p floatValue] / 100);
                } else {
                
                    NSRegularExpression* regexFraction = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]+)\\/([0-9]+)$" options:0 error:&error];
                    NSTextCheckingResult *matchFraction = [regexFraction firstMatchInString:expression options:0 range: searchedRange];
                    if(matchFraction){
                        // Fraction only
                        
                        NSString *top = [expression substringWithRange:[matchFraction rangeAtIndex:1]];
                        NSString *bottom = [expression substringWithRange:[matchFraction rangeAtIndex:2]];
                        CGFloat convertedFraction = [top floatValue] / [bottom floatValue];
                        dimension = full_dimension * convertedFraction;
                    }
                }
            }
            
        }
        
    }
    return dimension;
    
}
+ (NSString *)getSignature: (NSDictionary *)item{
    
    NSError *error;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:item options:0 error:&error];
    NSString * json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    
    NSString *pattern = @"\"(url|text)\"[ ]*:[ ]*\"([^\"]+)\"";
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSString *signature = [regex stringByReplacingMatchesInString:json
                                                          options:0
                                                            range:NSMakeRange(0, [json length])
                                                     withTemplate:@"\"jason\":\"jason\""];
    
    
    return signature;
    
}

+ (UIImage *)takescreenshot
{
    CGSize imageSize = CGSizeZero;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        imageSize = [UIScreen mainScreen].bounds.size;
    } else {
        imageSize = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    }
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, window.center.x, window.center.y);
        CGContextConcatCTM(context, window.transform);
        CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            CGContextRotateCTM(context, M_PI_2);
            CGContextTranslateCTM(context, 0, -imageSize.width);
        } else if (orientation == UIInterfaceOrientationLandscapeRight) {
            CGContextRotateCTM(context, -M_PI_2);
            CGContextTranslateCTM(context, -imageSize.height, 0);
        } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            CGContextRotateCTM(context, M_PI);
            CGContextTranslateCTM(context, -imageSize.width, -imageSize.height);
        }
        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
        } else {
            [window.layer renderInContext:context];
        }
        CGContextRestoreGState(context);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (NSString*) UTF8StringFromData:(NSData*)data
{
  // First we try strict decoding to avoid iconv overhead when not needed (majority of cases).
    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  if (!str)
  {
    // Here data contains invalid characters, so we'll try to clean them up.
      return [[NSString alloc] initWithData:[self dataByHealingUTF8Stream:data] encoding:NSUTF8StringEncoding];
  }
  return str;
}

// Replaces all broken sequences by � character and returns NSData with valid UTF-8 bytes.

+ (NSData*) dataByHealingUTF8Stream:(NSData *)data
{
  NSUInteger length = [data length];
  
  if (length == 0) return data;
  
#if DEBUG
  int warningsCounter = 10;
#endif
  
  //  bits
  //  7   	U+007F      0xxxxxxx
  //  11   	U+07FF      110xxxxx	10xxxxxx
  //  16  	U+FFFF      1110xxxx	10xxxxxx	10xxxxxx
  //  21  	U+1FFFFF    11110xxx	10xxxxxx	10xxxxxx	10xxxxxx
  //  26  	U+3FFFFFF   111110xx	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx
  //  31  	U+7FFFFFFF  1111110x	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx
  
  #define b00000000 0x00
  #define b10000000 0x80
  #define b11000000 0xc0
  #define b11100000 0xe0
  #define b11110000 0xf0
  #define b11111000 0xf8
  #define b11111100 0xfc
  #define b11111110 0xfe
  
  static NSString* replacementCharacter = @"�";
  NSData* replacementCharacterData = [replacementCharacter dataUsingEncoding:NSUTF8StringEncoding];
  
  NSMutableData* resultData = [NSMutableData dataWithCapacity:[data length]];
  
  const char *bytes = [data bytes];
  
  
  static const NSUInteger bufferMaxSize = 1024;
  char buffer[bufferMaxSize]; // not initialized, but will be filled in completely before copying to resultData
  NSUInteger bufferIndex = 0;
  
  #define FlushBuffer() if (bufferIndex > 0) { \
    [resultData appendBytes:buffer length:bufferIndex]; \
    bufferIndex = 0; \
  }
  #define CheckBuffer() if ((bufferIndex+5) >= bufferMaxSize) { \
    [resultData appendBytes:buffer length:bufferIndex]; \
    bufferIndex = 0; \
  }
  
  NSUInteger byteIndex = 0;
  BOOL invalidByte = NO;
  while (byteIndex < length)
  {
    char byte = bytes[byteIndex];
    
    // ASCII character is always a UTF-8 character
    if ((byte & b10000000) == b00000000) // 0xxxxxxx
    {
      CheckBuffer();
      buffer[bufferIndex++] = byte;
    }
    else if ((byte & b11100000) == b11000000) // 110xxxxx 10xxxxxx
    {
      if (byteIndex+1 >= length) {
        FlushBuffer();
        return resultData;
      }
      char byte2 = bytes[++byteIndex];
      if ((byte2 & b11000000) == b10000000)
      {
        // This 2-byte character still can be invalid. Check if we can create a string with it.
        unsigned char tuple[] = {byte, byte2};
        CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 2, kCFStringEncodingUTF8, false);
        if (cfstr)
        {
          CFRelease(cfstr);
          CheckBuffer();
          buffer[bufferIndex++] = byte;
          buffer[bufferIndex++] = byte2;
        }
        else
        {
          invalidByte = YES;
        }
      }
      else
      {
        byteIndex -= 1;
        invalidByte = YES;
      }
    }
    else if ((byte & b11110000) == b11100000) // 1110xxxx 10xxxxxx 10xxxxxx
    {
      if (byteIndex+2 >= length) {
        FlushBuffer();
        return resultData;
      }
      char byte2 = bytes[++byteIndex];
      char byte3 = bytes[++byteIndex];
      if ((byte2 & b11000000) == b10000000 && 
          (byte3 & b11000000) == b10000000)
      {
        // This 3-byte character still can be invalid. Check if we can create a string with it.
        unsigned char tuple[] = {byte, byte2, byte3};
        CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 3, kCFStringEncodingUTF8, false);
        if (cfstr)
        {
          CFRelease(cfstr);
          CheckBuffer();
          buffer[bufferIndex++] = byte;
          buffer[bufferIndex++] = byte2;
          buffer[bufferIndex++] = byte3;
        }
        else
        {
          invalidByte = YES;
        }
      }
      else
      {
        byteIndex -= 2;
        invalidByte = YES;
      }
    }
    else if ((byte & b11111000) == b11110000) // 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
    {
      if (byteIndex+3 >= length) {
        FlushBuffer();
        return resultData;
      }
      char byte2 = bytes[++byteIndex];
      char byte3 = bytes[++byteIndex];
      char byte4 = bytes[++byteIndex];
      if ((byte2 & b11000000) == b10000000 && 
          (byte3 & b11000000) == b10000000 && 
          (byte4 & b11000000) == b10000000)
      {
        // This 4-byte character still can be invalid. Check if we can create a string with it.
        unsigned char tuple[] = {byte, byte2, byte3, byte4};
        CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 4, kCFStringEncodingUTF8, false);
        if (cfstr)
        {
          CFRelease(cfstr);
          CheckBuffer();
          buffer[bufferIndex++] = byte;
          buffer[bufferIndex++] = byte2;
          buffer[bufferIndex++] = byte3;
          buffer[bufferIndex++] = byte4;
        }
        else
        {
          invalidByte = YES;
        }
      }
      else
      {
        byteIndex -= 3;
        invalidByte = YES;
      }
    }
    else if ((byte & b11111100) == b11111000) // 111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
    {
      if (byteIndex+4 >= length) {
        FlushBuffer();
        return resultData;
      }
      char byte2 = bytes[++byteIndex];
      char byte3 = bytes[++byteIndex];
      char byte4 = bytes[++byteIndex];
      char byte5 = bytes[++byteIndex];
      if ((byte2 & b11000000) == b10000000 && 
          (byte3 & b11000000) == b10000000 && 
          (byte4 & b11000000) == b10000000 && 
          (byte5 & b11000000) == b10000000)
      {
        // This 5-byte character still can be invalid. Check if we can create a string with it.
        unsigned char tuple[] = {byte, byte2, byte3, byte4, byte5};
        CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 5, kCFStringEncodingUTF8, false);
        if (cfstr)
        {
          CFRelease(cfstr);
          CheckBuffer();
          buffer[bufferIndex++] = byte;
          buffer[bufferIndex++] = byte2;
          buffer[bufferIndex++] = byte3;
          buffer[bufferIndex++] = byte4;
          buffer[bufferIndex++] = byte5;
        }
        else
        {
          invalidByte = YES;
        }
      }
      else
      {
        byteIndex -= 4;
        invalidByte = YES;
      }
    }
    else if ((byte & b11111110) == b11111100) // 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
    {
      if (byteIndex+5 >= length) {
        FlushBuffer();
        return resultData;
      }
      char byte2 = bytes[++byteIndex];
      char byte3 = bytes[++byteIndex];
      char byte4 = bytes[++byteIndex];
      char byte5 = bytes[++byteIndex];
      char byte6 = bytes[++byteIndex];
      if ((byte2 & b11000000) == b10000000 && 
          (byte3 & b11000000) == b10000000 && 
          (byte4 & b11000000) == b10000000 && 
          (byte5 & b11000000) == b10000000 &&
          (byte6 & b11000000) == b10000000)
      {
        // This 6-byte character still can be invalid. Check if we can create a string with it.
        unsigned char tuple[] = {byte, byte2, byte3, byte4, byte5, byte6};
        CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 6, kCFStringEncodingUTF8, false);
        if (cfstr)
        {
          CFRelease(cfstr);
          CheckBuffer();
          buffer[bufferIndex++] = byte;
          buffer[bufferIndex++] = byte2;
          buffer[bufferIndex++] = byte3;
          buffer[bufferIndex++] = byte4;
          buffer[bufferIndex++] = byte5;
          buffer[bufferIndex++] = byte6;
        }
        else
        {
          invalidByte = YES;
        }
        
      }
      else
      {
        byteIndex -= 5;
        invalidByte = YES;
      }
    }
    else
    {
      invalidByte = YES;
    }
    
    if (invalidByte)
    {
#if DEBUG
      if (warningsCounter)
      {
        warningsCounter--;
        //NSLog(@"NSData dataByHealingUTF8Stream: broken byte encountered at index %d", byteIndex);
      }
#endif
      invalidByte = NO;
      FlushBuffer();
      [resultData appendData:replacementCharacterData];
    }
    
    byteIndex++;
  }
  FlushBuffer();
  return resultData;
}
+ (NSArray *)childOf: (UIView *)view withClassName: (NSString *)className {
    NSMutableArray *f = [[NSMutableArray alloc] init];
    Class klass = NSClassFromString (className);
    if([view isKindOfClass:klass]){
        [f addObject:view];
    }
    if(view.subviews && view.subviews.count > 0){
        for(UIView *v in view.subviews){
            [f addObjectsFromArray: [self childOf:v withClassName:className]];
        }
    }
    return [f copy];
}
+ (id) read_local_json: (NSString *)url {
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *webrootPath = [resourcePath stringByAppendingPathComponent:@""];
    NSString *loc = @"file:/";
    
    NSString *jsonFile = [url stringByReplacingOccurrencesOfString:loc withString:webrootPath];
    NSLog(@"LOCALFILES jsonFile is %@", jsonFile);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    id ret;
    
    if ([fileManager fileExistsAtPath:jsonFile]) {
        NSError *error = nil;
        NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:jsonFile];
        [inputStream open];
        ret = [NSJSONSerialization JSONObjectWithStream: inputStream options:kNilOptions error:&error];
        [inputStream close];
    } else {
        NSLog(@"JASON FILE NOT FOUND: %@", jsonFile);
        ret = @{};
    }
    return ret;
}
+ (NSString *)normalized_url: (NSString *)url forOptions: (id)options{
    NSString *normalized_url = [url lowercaseString];
    normalized_url = [normalized_url stringByAppendingString:[NSString stringWithFormat:@"|%@", options]];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[/:]" options:NSRegularExpressionCaseInsensitive error:nil];
    normalized_url = [regex stringByReplacingMatchesInString:normalized_url options:0 range:NSMakeRange(0, [normalized_url length]) withTemplate:@"_"];
    normalized_url = [[normalized_url componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    return normalized_url;
}

@end
