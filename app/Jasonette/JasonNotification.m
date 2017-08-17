//
//  JasonNotification.m
//  Jasonette
//
//  Created by Camilo Castro on 17-08-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonNotification.h"
#import "JasonNotificationCenter.h"

@implementation JasonNotification

- (NSString *) name
{
  if(!_name)
  {
    _name = @"";
  }
  
  return _name;
}

- (NSString *) message
{
  if(!_message)
  {
    _message = @"";
  }
  
  return _message;
}

- (id) data
{
  if(!_data)
  {
    _data = nil;
  }
  
  return _data;
}

- (instancetype _Nullable) initWithName: (nonnull NSString *) name
{
  self = [super init];
  
  if(self)
  {
      self.name = name;
  }
  
  return self;
}

- (instancetype _Nullable) initWithName: (nonnull NSString *) name
                             andMessage: (nonnull NSString *) message
{
  self = [super init];
  
  if(self)
  {
    self.name = name;
    self.message = message;
  }
  
  return self;
}

- (instancetype _Nullable) initWithName: (nonnull NSString *) name
                                message: (nonnull NSString *) message
                                andData: (nullable id) data
{
  self = [super init];
  
  if(self)
  {
    self.name = name;
    self.message = message;
    self.data = data;
  }
  
  return self;
}


- (NSString *) description
{
  NSString * info = self.message;
  
  if(self.data)
  {
    info = [NSString
            stringWithFormat:@"%@\nData: %@", self.message, self.data];
  }
  
  return info;
}

- (void) trigger
{
  [JasonNotificationCenter
   postNotification:self];
}


@end
