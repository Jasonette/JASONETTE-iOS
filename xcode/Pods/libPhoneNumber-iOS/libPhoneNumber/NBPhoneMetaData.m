//
//  NBPhoneMetaData.m
//  libPhoneNumber
//
//

#import "NBPhoneMetaData.h"
#import "NBNumberFormat.h"
#import "NBPhoneNumberDesc.h"
#import "NSArray+NBAdditions.h"

@implementation NBPhoneMetaData

- (instancetype)init {
  self = [super init];

  if (self) {
    _numberFormats = [[NSMutableArray alloc] init];
    _intlNumberFormats = [[NSMutableArray alloc] init];

    _leadingZeroPossible = NO;
    _mainCountryForCode = NO;
    _sameMobileAndFixedLinePattern = NO;
    _internationalPrefix = @"NA";
  }

  return self;
}

- (instancetype)initWithEntry:(NSArray *)entry {
  self = [super init];
  if (self && entry != nil) {
    _generalDesc = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:1]];
    _fixedLine = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:2]];
    _mobile = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:3]];
    _tollFree = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:4]];
    _premiumRate = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:5]];
    _sharedCost = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:6]];
    _personalNumber = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:7]];
    _voip = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:8]];
    _pager = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:21]];
    _uan = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:25]];
    _emergency = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:27]];
    _voicemail = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:28]];
    _noInternationalDialling =
        [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:24]];
    _codeID = [entry nb_safeStringAtIndex:9];
    _countryCode = [entry nb_safeNumberAtIndex:10];
    _internationalPrefix = [entry nb_safeStringAtIndex:11];
    _preferredInternationalPrefix = [entry nb_safeStringAtIndex:17];
    _nationalPrefix = [entry nb_safeStringAtIndex:12];
    _preferredExtnPrefix = [entry nb_safeStringAtIndex:13];
    _nationalPrefixForParsing = [entry nb_safeStringAtIndex:15];
    _nationalPrefixTransformRule = [entry nb_safeStringAtIndex:16];
    _sameMobileAndFixedLinePattern = [[entry nb_safeNumberAtIndex:18] boolValue];
    _numberFormats = [self numberFormatsFromEntry:[entry nb_safeArrayAtIndex:19]];
    _intlNumberFormats = [self numberFormatsFromEntry:[entry nb_safeArrayAtIndex:20]];
    _mainCountryForCode = [[entry nb_safeNumberAtIndex:22] boolValue];
    _leadingDigits = [entry nb_safeStringAtIndex:23];
    _leadingZeroPossible = [[entry nb_safeNumberAtIndex:26] boolValue];

#if SHORT_NUMBER_SUPPORT
    _shortCode = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:29]];
    _standardRate = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:30]];
    _carrierSpecific = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:31]];
    _smsServices = [[NBPhoneNumberDesc alloc] initWithEntry:[entry nb_safeArrayAtIndex:33]];
#endif // SHORT_NUMBER_SUPPORT
  }

  return self;
}

- (NSArray<NBNumberFormat *> *)numberFormatsFromEntry:(NSArray *)entry {
  NSMutableArray *formats = [NSMutableArray arrayWithCapacity:entry.count];
  for (NSArray *format in entry) {
    NBNumberFormat *numberFormat = [[NBNumberFormat alloc] initWithEntry:format];
    [formats addObject:numberFormat];
  }
  return formats;
}

- (NSString *)description {
  return [NSString
      stringWithFormat:
          @"* codeID[%@] countryCode[%@] generalDesc[%@] fixedLine[%@] mobile[%@] tollFree[%@] "
          @"premiumRate[%@] sharedCost[%@] personalNumber[%@] voip[%@] pager[%@] uan[%@] "
          @"emergency[%@] voicemail[%@] noInternationalDialling[%@] internationalPrefix[%@] "
          @"preferredInternationalPrefix[%@] nationalPrefix[%@] preferredExtnPrefix[%@] "
          @"nationalPrefixForParsing[%@] nationalPrefixTransformRule[%@] "
          @"sameMobileAndFixedLinePattern[%@] numberFormats[%@] intlNumberFormats[%@] "
          @"mainCountryForCode[%@] leadingDigits[%@] leadingZeroPossible[%@]",
          _codeID, _countryCode, _generalDesc, _fixedLine, _mobile, _tollFree, _premiumRate,
          _sharedCost, _personalNumber, _voip, _pager, _uan, _emergency, _voicemail,
          _noInternationalDialling, _internationalPrefix, _preferredInternationalPrefix,
          _nationalPrefix, _preferredExtnPrefix, _nationalPrefixForParsing,
          _nationalPrefixTransformRule, _sameMobileAndFixedLinePattern ? @"Y" : @"N",
          _numberFormats, _intlNumberFormats, _mainCountryForCode ? @"Y" : @"N", _leadingDigits,
          _leadingZeroPossible ? @"Y" : @"N"];
}

#ifdef NB_USE_EXTENSIONS
// We believe these methods are unused.
// If you would like them back (not behind a flag) please file a bug with a reason for needing
// them.

- (instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [super init]) {
    _generalDesc = [coder decodeObjectForKey:@"generalDesc"];
    _fixedLine = [coder decodeObjectForKey:@"fixedLine"];
    _mobile = [coder decodeObjectForKey:@"mobile"];
    _tollFree = [coder decodeObjectForKey:@"tollFree"];
    _premiumRate = [coder decodeObjectForKey:@"premiumRate"];
    _sharedCost = [coder decodeObjectForKey:@"sharedCost"];
    _personalNumber = [coder decodeObjectForKey:@"personalNumber"];
    _voip = [coder decodeObjectForKey:@"voip"];
    _pager = [coder decodeObjectForKey:@"pager"];
    _uan = [coder decodeObjectForKey:@"uan"];
    _emergency = [coder decodeObjectForKey:@"emergency"];
    _voicemail = [coder decodeObjectForKey:@"voicemail"];
    _noInternationalDialling = [coder decodeObjectForKey:@"noInternationalDialling"];
    _codeID = [coder decodeObjectForKey:@"codeID"];
    _countryCode = [coder decodeObjectForKey:@"countryCode"];
    _internationalPrefix = [coder decodeObjectForKey:@"internationalPrefix"];
    _preferredInternationalPrefix = [coder decodeObjectForKey:@"preferredInternationalPrefix"];
    _nationalPrefix = [coder decodeObjectForKey:@"nationalPrefix"];
    _preferredExtnPrefix = [coder decodeObjectForKey:@"preferredExtnPrefix"];
    _nationalPrefixForParsing = [coder decodeObjectForKey:@"nationalPrefixForParsing"];
    _nationalPrefixTransformRule = [coder decodeObjectForKey:@"nationalPrefixTransformRule"];
    _sameMobileAndFixedLinePattern =
        [[coder decodeObjectForKey:@"sameMobileAndFixedLinePattern"] boolValue];
    _numberFormats = [coder decodeObjectForKey:@"numberFormats"];
    _intlNumberFormats = [coder decodeObjectForKey:@"intlNumberFormats"];
    _mainCountryForCode = [[coder decodeObjectForKey:@"mainCountryForCode"] boolValue];
    _leadingDigits = [coder decodeObjectForKey:@"leadingDigits"];
    _leadingZeroPossible = [[coder decodeObjectForKey:@"leadingZeroPossible"] boolValue];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:_generalDesc forKey:@"generalDesc"];
  [coder encodeObject:_fixedLine forKey:@"fixedLine"];
  [coder encodeObject:_mobile forKey:@"mobile"];
  [coder encodeObject:_tollFree forKey:@"tollFree"];
  [coder encodeObject:_premiumRate forKey:@"premiumRate"];
  [coder encodeObject:_sharedCost forKey:@"sharedCost"];
  [coder encodeObject:_personalNumber forKey:@"personalNumber"];
  [coder encodeObject:_voip forKey:@"voip"];
  [coder encodeObject:_pager forKey:@"pager"];
  [coder encodeObject:_uan forKey:@"uan"];
  [coder encodeObject:_emergency forKey:@"emergency"];
  [coder encodeObject:_voicemail forKey:@"voicemail"];
  [coder encodeObject:_noInternationalDialling forKey:@"noInternationalDialling"];
  [coder encodeObject:_codeID forKey:@"codeID"];
  [coder encodeObject:_countryCode forKey:@"countryCode"];
  [coder encodeObject:_internationalPrefix forKey:@"internationalPrefix"];
  [coder encodeObject:_preferredInternationalPrefix forKey:@"preferredInternationalPrefix"];
  [coder encodeObject:_nationalPrefix forKey:@"nationalPrefix"];
  [coder encodeObject:_preferredExtnPrefix forKey:@"preferredExtnPrefix"];
  [coder encodeObject:_nationalPrefixForParsing forKey:@"nationalPrefixForParsing"];
  [coder encodeObject:_nationalPrefixTransformRule forKey:@"nationalPrefixTransformRule"];
  [coder encodeObject:[NSNumber numberWithBool:_sameMobileAndFixedLinePattern]
               forKey:@"sameMobileAndFixedLinePattern"];
  [coder encodeObject:_numberFormats forKey:@"numberFormats"];
  [coder encodeObject:_intlNumberFormats forKey:@"intlNumberFormats"];
  [coder encodeObject:[NSNumber numberWithBool:_mainCountryForCode] forKey:@"mainCountryForCode"];
  [coder encodeObject:_leadingDigits forKey:@"leadingDigits"];
  [coder encodeObject:[NSNumber numberWithBool:_leadingZeroPossible] forKey:@"leadingZeroPossible"];
}

#endif  // NB_USE_EXTENSIONS

@end
