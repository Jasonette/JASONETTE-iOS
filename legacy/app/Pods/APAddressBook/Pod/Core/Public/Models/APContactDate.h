//
//  APContactDate.h
//  APAddressBook
//
//  Created by Alexandre Plisson on 14/01/2016.
//
//

#import <Foundation/Foundation.h>

@interface APContactDate : NSObject

@property (nullable, nonatomic, strong) NSDate *date;
@property (nullable, nonatomic, strong) NSString *originalLabel;
@property (nullable, nonatomic, strong) NSString *localizedLabel;

@end
