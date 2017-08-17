//
//  JasonNotificationWrongHeaderFormat.m
//  Jasonette
//
//  Created by Camilo Castro on 17-08-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonNotificationWrongHeaderFormat.h"

NSString * _Nonnull const kJasonNotificationWrongHeaderFormat = @"com.jasonette.notifications:warnings.wrong.header.format";

@implementation JasonNotificationWrongHeaderFormat

- (NSString *) key
{
  if (!_key) {
    _key = @"";
  }
  
  return _key;
}

- (id) value
{
  if(!_value)
  {
    _value = @"null";
  }
  
  return _value;
}

- (instancetype _Nullable) initWithData: (nonnull id) data
{
  self = [super initWithName:kJasonNotificationWrongHeaderFormat
                     message:@"Wrong Header Format. Header must be a String."
                     andData:data];
  
  return self;
}

- (instancetype _Nullable) initWithKey: (nonnull NSString *) key
                              andValue: (nullable id) value
{
  
  self.key = key;
  
  if(value)
  {
    self = [self initWithData:@{@"key" : key, @"value" : value}];
    self.value = value;
  }
  else
  {
    self = [self initWithData:@{@"key" : key, @"value" : @"null"}];
    self.value = @"null";
  }
  
  return self;
}

@end
