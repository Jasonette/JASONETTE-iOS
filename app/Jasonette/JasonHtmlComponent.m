//
//  JasonHtmlComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonHtmlComponent.h"

@implementation JasonHtmlComponent
+ (UIView *)build: (UILabel *)component withJSON: (NSDictionary *)json withOptions: (NSDictionary *)options{

    if(!component){
        component = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    if(json[@"text"] && ![[NSNull null] isEqual:json[@"text"]]){
        NSString *html = json[@"text"];
        if(json[@"css"]){
            html = [self styledHTMLwithHTML:html withStyle:json[@"css"]];
        }
        NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *options = @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)};
        NSAttributedString *str = [[NSAttributedString alloc] initWithData:data options:options documentAttributes:NULL error:NULL];
        component.numberOfLines = 0;
        component.attributedText = str;
        [component sizeToFit];
    }
    
    return component;
}
+ (NSString *)styledHTMLwithHTML:(NSString *)HTML withStyle: (NSString *)style{
    
    
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    
    return [NSString stringWithFormat:@"<meta charset=\"UTF-8\"><style>body{width: %fpx; height: %fpx;}%@</style>%@", width, height, style, HTML];
}

+ (NSAttributedString *)attributedStringWithHTML:(NSString *)HTML {
    NSDictionary *options = @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType };
    return [[NSAttributedString alloc] initWithData:[HTML dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:NULL error:NULL];
}


@end
