// Copyright 2016-present the Material Components for iOS authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "MDCPaletteExpansions.h"

#include <Foundation/Foundation.h>

#import "MDCPaletteNames.h"

// Observed saturation ranges for tints 50, 500, 900.
static const CGFloat kSaturation50Min = (CGFloat)0.06;
static const CGFloat kSaturation50Max = (CGFloat)0.12;
static const CGFloat kSaturation500Min = (CGFloat)0.60;
static const CGFloat kSaturation500Max = 1;
static const CGFloat kSaturation900Min = (CGFloat)0.70;
static const CGFloat kSaturation900Max = 1;

// Minimum value of saturation to consider a color "colorless" (e.g. white/black/grey).
static const CGFloat kSaturationMinThreshold = 1 / (CGFloat)256;

// A small value for comparing floating point numbers that is appropriate for color components.
static const CGFloat kComponentEpsilon = (CGFloat)0.5 / 256;

// Observed brightness ranges for tints 50, 500, 900.
static const CGFloat kBrightness50Min = (CGFloat)0.95;
static const CGFloat kBrightness50Max = 1;
static const CGFloat kBrightness500Min = (CGFloat)0.50;
static const CGFloat kBrightness500Max = 1;

// Observed quadratic brightness coefficients for tints >= 500.
static const CGFloat kBrightnessQuadracticCoeff = (CGFloat)-0.00642857142857143;
static const CGFloat kBrightnessLinearCoeff = (CGFloat)-0.03585714285714282;

// Median saturation and brightness values for A100, A200, A400, A700.
static const CGFloat kAccentSaturation[4] = {(CGFloat)0.49, (CGFloat)0.75, 1, 1};
static const CGFloat kAccentBrightness[4] = {1, 1, 1, (CGFloat)0.92};

// Ordered indices of each of the tints/accents.
static const int kQTMColorTint50Index = 0;
static const int kQTMColorTint100Index = 1;
static const int kQTMColorTint200Index = 2;
static const int kQTMColorTint300Index = 3;
static const int kQTMColorTint400Index = 4;
static const int kQTMColorTint500Index = 5;
static const int kQTMColorTint600Index = 6;
static const int kQTMColorTint700Index = 7;
static const int kQTMColorTint800Index = 8;
static const int kQTMColorTint900Index = 9;
static const int kQTMColorAccent100Index = 10;
static const int kQTMColorAccent200Index = 11;
static const int kQTMColorAccent400Index = 12;
static const int kQTMColorAccent700Index = 13;

/** Returns a value Clamped to the range [min, max]. */
static inline CGFloat Clamp(CGFloat value, CGFloat min, CGFloat max) {
  if (value < min) {
    return min;
  } else if (value > max) {
    return max;
  } else {
    return value;
  }
}

/** Returns the linear interpolation of [min, max] at value. */
static inline CGFloat Lerp(CGFloat value, CGFloat min, CGFloat max) {
  return (1 - value) * min + value * max;
}

/** Returns the value t such that Lerp(t, min, max) == value. */
static inline CGFloat InvLerp(CGFloat value, CGFloat min, CGFloat max) {
  return (value - min) / (max - min);
}

/**
 Returns "component > value", but accounting for floating point mathematics. The component is
 expected to be between [0,255].
 */
static inline BOOL IsComponentGreaterThanValue(CGFloat component, CGFloat value) {
  return component + kComponentEpsilon > value;
}

static void ColorToHSB(UIColor *_Nonnull color, CGFloat hsb[4]) {
  // Pre-iOS 8 would not convert greyscale colors to HSB.
  if (![color getHue:&hsb[0] saturation:&hsb[1] brightness:&hsb[2] alpha:&hsb[3]]) {
    // Greyscale colors have hue and saturation of zero.
    hsb[0] = 0;
    hsb[1] = 0;
    if (![color getWhite:&hsb[2] alpha:&hsb[3]]) {
      NSCAssert(NO, @"Could not extract HSB from target color %@", color);
      hsb[2] = 0;
      hsb[3] = 0;
    }
  }
}

/** Return the ordered index of a tint/accent by name. */
static int NameToIndex(NSString *_Nonnull name) {
  static NSDictionary *map = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      MDC_PALETTE_TINT_50_INTERNAL_NAME : @(kQTMColorTint50Index),
      MDC_PALETTE_TINT_100_INTERNAL_NAME : @(kQTMColorTint100Index),
      MDC_PALETTE_TINT_200_INTERNAL_NAME : @(kQTMColorTint200Index),
      MDC_PALETTE_TINT_300_INTERNAL_NAME : @(kQTMColorTint300Index),
      MDC_PALETTE_TINT_400_INTERNAL_NAME : @(kQTMColorTint400Index),
      MDC_PALETTE_TINT_500_INTERNAL_NAME : @(kQTMColorTint500Index),
      MDC_PALETTE_TINT_600_INTERNAL_NAME : @(kQTMColorTint600Index),
      MDC_PALETTE_TINT_700_INTERNAL_NAME : @(kQTMColorTint700Index),
      MDC_PALETTE_TINT_800_INTERNAL_NAME : @(kQTMColorTint800Index),
      MDC_PALETTE_TINT_900_INTERNAL_NAME : @(kQTMColorTint900Index),
      MDC_PALETTE_ACCENT_100_INTERNAL_NAME : @(kQTMColorAccent100Index),
      MDC_PALETTE_ACCENT_200_INTERNAL_NAME : @(kQTMColorAccent200Index),
      MDC_PALETTE_ACCENT_400_INTERNAL_NAME : @(kQTMColorAccent400Index),
      MDC_PALETTE_ACCENT_700_INTERNAL_NAME : @(kQTMColorAccent700Index)
    };
  });

  NSNumber *index = map[name];
  if (index != nil) {
    return [index intValue];
  } else {
    NSCAssert(NO, @"%@ is not a valid tint/accent name.", name);
    return kQTMColorTint500Index;
  }
}

UIColor *MDCPaletteTintFromTargetColor(UIColor *targetColor, NSString *tintName) {
  NSCAssert(MDCPaletteIsTintOrAccentName(tintName), @"Invalid tint/accent name %@.", tintName);
  int tint = NameToIndex(tintName);

  CGFloat hsb[4];
  ColorToHSB(targetColor, hsb);

  // Saturation: select a saturation curve from the input saturation, unless the saturation is so
  // low to be considered 'colorless', e.g. white/black/grey, in which case skip this step.
  CGFloat saturation = hsb[1];
  CGFloat t;
  if (IsComponentGreaterThanValue(hsb[1], kSaturationMinThreshold)) {
    // Limit saturation to observed values.
    hsb[1] = Clamp(hsb[1], kSaturation500Min, kSaturation500Max);

    t = InvLerp(hsb[1], kSaturation500Min, kSaturation500Max);
    if (tint <= kQTMColorTint500Index) {
      CGFloat saturation50 = Lerp(t, kSaturation50Min, kSaturation50Max);
      CGFloat u = InvLerp(tint, kQTMColorTint50Index, kQTMColorTint500Index);
      saturation = Lerp(u, saturation50, hsb[1]);
    } else {
      CGFloat saturation900 = Lerp(t, kSaturation900Min, kSaturation900Max);
      CGFloat u = InvLerp(tint, kQTMColorTint500Index, kQTMColorTint900Index);
      saturation = Lerp(u, hsb[1], saturation900);
    }
  }

  // Brightness: select a brightness curve from the input brightness.
  CGFloat brightness;

  // Limit brightness to observed values.
  hsb[2] = Clamp(hsb[2], kBrightness500Min, kBrightness500Max);
  t = InvLerp(hsb[2], kBrightness500Min, kBrightness500Max);

  // The tints 50-500 are nice and linear.
  if (tint <= kQTMColorTint500Index) {
    CGFloat brightness50 = Lerp(t, kBrightness50Min, kBrightness50Max);
    CGFloat u = InvLerp(tint, kQTMColorTint50Index, kQTMColorTint500Index);
    brightness = Lerp(u, brightness50, hsb[2]);

    // The tints > 500 fall off roughly quadratically.
  } else {
    CGFloat u = tint - kQTMColorTint500Index;
    brightness = hsb[2] + kBrightnessQuadracticCoeff * u * u + kBrightnessLinearCoeff * u;
  }

  return [UIColor colorWithHue:hsb[0] saturation:saturation brightness:brightness alpha:1];
}

UIColor *MDCPaletteAccentFromTargetColor(UIColor *targetColor, NSString *accentName) {
  NSCAssert(MDCPaletteIsTintOrAccentName(accentName), @"Invalid tint/accent name %@.", accentName);
  int accent = NameToIndex(accentName);

  CGFloat hsb[4];
  ColorToHSB(targetColor, hsb);

  int index = accent - kQTMColorAccent100Index;
  NSCAssert(index >= 0 && index < 4, @"Invalid accent index %i", (int)accent);

  CGFloat saturation = IsComponentGreaterThanValue(hsb[1], kSaturationMinThreshold)
                           ? kAccentSaturation[index]
                           : hsb[1];
  CGFloat brightness = kAccentBrightness[index];
  return [UIColor colorWithHue:hsb[0] saturation:saturation brightness:brightness alpha:1];
}
