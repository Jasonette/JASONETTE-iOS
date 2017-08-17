//
//  JasonNotification.h
//  Jasonette
//
//  Created by Camilo Castro on 17-08-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JasonNotification : NSObject

@property (nonatomic, nonnull) NSString * name;

@property (nonatomic, nonnull) NSString * message;

@property (nonatomic, nullable) id data;

- (instancetype _Nullable) initWithName: (nonnull NSString *) name;
- (instancetype _Nullable) initWithName: (nonnull NSString *) name andMessage: (nonnull NSString *) message;
- (instancetype _Nullable) initWithName: (nonnull NSString *) name message: (nonnull NSString *) message andData: (nullable id) data;

- (void) trigger;
@end
