//
//  JasonNotificationWrongHeaderFormat.h
//  Jasonette
//
//  Created by Camilo Castro on 17-08-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonNotification.h"

extern NSString * _Nonnull const kJasonNotificationWrongHeaderFormat;

@interface JasonNotificationWrongHeaderFormat : JasonNotification

@property (nonatomic, nonnull) NSString * key;
@property (nonatomic, nonnull) id value;

- (instancetype _Nullable) initWithData: (nonnull id) data;

- (instancetype _Nullable) initWithKey: (nonnull NSString *) key andValue: (nullable id) value;

@end
