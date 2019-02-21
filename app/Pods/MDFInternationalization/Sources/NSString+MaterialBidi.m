/*
 Copyright 2018-present Google Inc. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "NSString+MaterialBidi.h"

#import <CoreFoundation/CoreFoundation.h>

@implementation NSString (MaterialBidi)

// https://www.w3.org/International/questions/qa-bidi-unicode-controls
//TODO: Reach out to AAA about the utility of the Isolate markers
// ??? Do we want Embedding or Isolate markers? w3 recommends isolate?
// Add reference : Unicode® Standard Annex #9 UNICODE BIDIRECTIONAL ALGORITHM
// go/android-bidiformatter
// http://unicode.org/reports/tr9/

// Mark influences the directionality of neutral characters when the context is opposite of the
// neutral chatacter's desired directionality.
static NSString *kMDFLTRMark = @"\u200e";  // left-to-right mark
static NSString *kMDFRTLMark = @"\u200f";  // right-to-left mark

// Embedding indicates a text segment is embedded in a larger context with the opposite
// directionality.
static NSString *kMDFLTREmbedding = @"\u202a";  // left-to-right embedding
static NSString *kMDFRTLEmbedding = @"\u202b";  // right-to-left embedding

// Override reverses the directionality of strongly LTR or RTL characters
static NSString *kMDFLTROverride = @"\u202d";  // left-to-right override
static NSString *kMDFRTLOverride = @"\u202e";  // right-to-left override

// Pop is used to denote the end of an embedding or override text segment
static NSString *kMDFPopFormatting = @"\u202c";  // pop directional formatting

// Version 6.3.0 Bidi algorithm additions
// The following only work on iOS 10+

// Isolate indicates that the text segment has an internal directionality with no effect on
// surrounding characters.
static NSString *kMDFLTRIsolate = @"\u2066";  // left-to-right isolate
static NSString *kMDFRTLIsolate = @"\u2067";  // right-to-left isolate
static NSString *kMDFFirstStrongIsolate = @"\u2068";  // first strong isolate

// Pop Isolate is used to denote the end of an isolate text segment
static NSString *kMDFPopIsolate = @"\u2069";  // pop directional isolate


- (NSLocaleLanguageDirection)mdf_calculatedLanguageDirection {
  // Attempt to determine language of string.
  NSLocaleLanguageDirection languageDirection = NSLocaleLanguageDirectionUnknown;

  // Pass string into CoreFoundation's language identifier
  CFStringRef text = (__bridge CFStringRef)self;
  CFRange range = CFRangeMake(0, (CFIndex)[self length]);
  NSString *languageCode =
      (NSString *)CFBridgingRelease(CFStringTokenizerCopyBestStringLanguage(text, range));
  if (languageCode) {
    // If we identified a language, explicitly set the string direction based on that
    languageDirection = [NSLocale characterDirectionForLanguage:languageCode];
  }

  // If the result is not LTR or RTL, fallback to LTR
  // ??? Should I be defaulting to NSLocale.NSLocaleLanguageCode.characterDiretion?
  if (languageDirection != NSLocaleLanguageDirectionLeftToRight &&
      languageDirection != NSLocaleLanguageDirectionRightToLeft) {
    languageDirection = NSLocaleLanguageDirectionLeftToRight;
  }

  return languageDirection;
}

- (NSString *)mdf_stringWithBidiEmbedding {
  NSLocaleLanguageDirection languageDirection = [self mdf_calculatedLanguageDirection];

  return [self mdf_stringWithBidiEmbedding:languageDirection];
}

- (NSString *)mdf_stringWithBidiEmbedding:(NSLocaleLanguageDirection)languageDirection {
  if (languageDirection == NSLocaleLanguageDirectionRightToLeft) {
    return [NSString stringWithFormat:@"%@%@%@", kMDFRTLEmbedding, self, kMDFPopFormatting];
  } else if (languageDirection == NSLocaleLanguageDirectionLeftToRight) {
    return [NSString stringWithFormat:@"%@%@%@", kMDFLTREmbedding, self, kMDFPopFormatting];
  } else {
    // Return a copy original string if an unsupported direction is passed in.
    return [self copy];
  }
}

- (nonnull NSString *)mdf_stringWithStereoReset:(NSLocaleLanguageDirection)direction
                                          context:(NSLocaleLanguageDirection)contextDirection {
#if DEBUG
  // Disable in release, as a pre-caution in case not everyone defines NS_BLOCK_ASSERTION.
  NSCAssert((contextDirection != NSLocaleLanguageDirectionLeftToRight ||
             contextDirection != NSLocaleLanguageDirectionRightToLeft),
            @"contextStringDirection must be passed in and set to either"
            "NSLocaleLanguageDirectionLeftToRight or NSLocaleLanguageDirectionRightToLeft.");

  NSCAssert((direction != NSLocaleLanguageDirectionLeftToRight ||
             direction != NSLocaleLanguageDirectionRightToLeft ||
             direction != NSLocaleLanguageDirectionUnknown),
            @"stringToBeInsertedDirection must be set to either NSLocaleLanguageDirectionUnknown,"
            "NSLocaleLanguageDirectionLeftToRight, or NSLocaleLanguageDirectionRightToLeft.");
#endif

  if (self.length == 0) {
    return [self copy];
  }

  if (direction != NSLocaleLanguageDirectionLeftToRight &&
      direction != NSLocaleLanguageDirectionRightToLeft) {
    direction = [self mdf_calculatedLanguageDirection];
  }

  NSString *bidiEmbeddedString = [self mdf_stringWithBidiEmbedding:direction];

  NSString *bidiResetString;
  if (direction != contextDirection) {
    if (contextDirection == NSLocaleLanguageDirectionRightToLeft) {
      bidiResetString =
          [NSString stringWithFormat:@"%@%@%@", kMDFRTLMark, bidiEmbeddedString, kMDFRTLMark];
    } else {
      bidiResetString =
          [NSString stringWithFormat:@"%@%@%@", kMDFLTRMark, bidiEmbeddedString, kMDFLTRMark];
    }
  } else {
    bidiResetString = bidiEmbeddedString;
  }

  return bidiResetString;
}

- (NSString *)mdf_stringWithBidiMarkersStripped {
  NSString *strippedString = self;
  NSArray <NSString *>*directionalMarkers = @[ kMDFLTRMark,
                                               kMDFRTLMark,
                                               kMDFRTLEmbedding,
                                               kMDFLTREmbedding,
                                               kMDFRTLOverride,
                                               kMDFLTROverride,
                                               kMDFPopFormatting,
                                               kMDFLTRIsolate,
                                               kMDFRTLIsolate,
                                               kMDFFirstStrongIsolate,
                                               kMDFPopIsolate
                                               ];
  for (NSString *markerString in directionalMarkers) {
    strippedString =
        [strippedString stringByReplacingOccurrencesOfString:markerString withString:@""];
  }
  return strippedString;
}

@end
