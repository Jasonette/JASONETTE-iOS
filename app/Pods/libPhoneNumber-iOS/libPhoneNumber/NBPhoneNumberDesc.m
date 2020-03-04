//
//  NBPhoneNumberDesc.m
//  libPhoneNumber
//
//

#import "NBPhoneNumberDesc.h"
#import "NSArray+NBAdditions.h"

@implementation NBPhoneNumberDesc

- (instancetype)initWithEntry:(NSArray *)entry {
  self = [super init];
  if (self && entry != nil) {
    _nationalNumberPattern = [entry nb_safeStringAtIndex:2];
    _possibleNumberPattern = [entry nb_safeStringAtIndex:3];
    _possibleLength = [entry nb_safeArrayAtIndex:9];
    _possibleLengthLocalOnly = [entry nb_safeArrayAtIndex:10];
    _exampleNumber = [entry nb_safeStringAtIndex:6];
    _nationalNumberMatcherData = [entry nb_safeDataAtIndex:7];
    _possibleNumberMatcherData = [entry nb_safeDataAtIndex:8];
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:
                       @"nationalNumberPattern[%@] possibleNumberPattern[%@] possibleLength[%@] "
                       @"possibleLengthLocalOnly[%@] exampleNumber[%@]",
                       self.nationalNumberPattern, self.possibleNumberPattern, self.possibleLength,
                       self.possibleLengthLocalOnly, self.exampleNumber];
}

#ifdef NB_USE_EXTENSIONS
// We believe these methods are unused.
// If you would like them back (not behind a flag) please file a bug with a reason for needing
// them.

- (instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [super init]) {
    _nationalNumberPattern = [coder decodeObjectForKey:@"nationalNumberPattern"];
    _possibleNumberPattern = [coder decodeObjectForKey:@"possibleNumberPattern"];
    _possibleLength = [coder decodeObjectForKey:@"possibleLength"];
    _possibleLengthLocalOnly = [coder decodeObjectForKey:@"possibleLengthLocalOnly"];
    _exampleNumber = [coder decodeObjectForKey:@"exampleNumber"];
    _nationalNumberMatcherData = [coder decodeObjectForKey:@"nationalNumberMatcherData"];
    _possibleNumberMatcherData = [coder decodeObjectForKey:@"possibleNumberMatcherData"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.nationalNumberPattern forKey:@"nationalNumberPattern"];
  [coder encodeObject:self.possibleNumberPattern forKey:@"possibleNumberPattern"];
  [coder encodeObject:self.possibleLength forKey:@"possibleLength"];
  [coder encodeObject:self.possibleLengthLocalOnly forKey:@"possibleLengthLocalOnly"];
  [coder encodeObject:self.exampleNumber forKey:@"exampleNumber"];
  [coder encodeObject:self.nationalNumberMatcherData forKey:@"nationalNumberMatcherData"];
  [coder encodeObject:self.possibleNumberMatcherData forKey:@"possibleNumberMatcherData"];
}

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

- (BOOL)isEqual:(id)object {
  if ([object isKindOfClass:[NBPhoneNumberDesc class]] == NO) {
    return NO;
  }

  NBPhoneNumberDesc *other = object;
  return [self.nationalNumberPattern isEqual:other.nationalNumberPattern] &&
         [self.possibleNumberPattern isEqual:other.possibleNumberPattern] &&
         [self.possibleLength isEqual:other.possibleLength] &&
         [self.possibleLengthLocalOnly isEqual:other.possibleLengthLocalOnly] &&
         [self.exampleNumber isEqual:other.exampleNumber] &&
         [self.nationalNumberMatcherData isEqualToData:other.nationalNumberMatcherData] &&
         [self.possibleNumberMatcherData isEqualToData:other.possibleNumberMatcherData];
}

#endif  // NB_USE_EXTENSIONS

@end
