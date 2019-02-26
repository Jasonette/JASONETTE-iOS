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

/*
 The string values of the names of the tints and accents are required in two places:
   - in the definitions of the API names (such as MDCPaletteTint500Name)
   - in the private implementation, for example, to check incoming strings are correct.

 We can't have both the public and the private implementations depending on each other, since that
 would cause a dependency loop. The normal solution to a dependency loop is to factor out the
 common part into a new "unit" and have both of the original implementations depend on this new
 unit. In this case, the string values would get factored out into the new unit.

 However, the code in question is initializing constant data (the strings), the definitions must use
 compile-time constants. For example, if we factored out the string values as "internal" names, the
 following would still not work because the initialization doesn't use compile-time constants.

 ```objective-c
 static const NSString *MDCPaletteTint500Name = MDCPaletteTint500InternalName;
 ```

 To get around this, we instead drop down a level and define the strings in the preprocessor, so
 that the compiler still sees compile-time constants. This has the downside of possibly duplicating
 strings if the compiler can't optimize string storage across compilation units.
 */

#import <Foundation/Foundation.h>

#define MDC_PALETTE_TINT_50_INTERNAL_NAME @"50"
#define MDC_PALETTE_TINT_100_INTERNAL_NAME @"100"
#define MDC_PALETTE_TINT_200_INTERNAL_NAME @"200"
#define MDC_PALETTE_TINT_300_INTERNAL_NAME @"300"
#define MDC_PALETTE_TINT_400_INTERNAL_NAME @"400"
#define MDC_PALETTE_TINT_500_INTERNAL_NAME @"500"
#define MDC_PALETTE_TINT_600_INTERNAL_NAME @"600"
#define MDC_PALETTE_TINT_700_INTERNAL_NAME @"700"
#define MDC_PALETTE_TINT_800_INTERNAL_NAME @"800"
#define MDC_PALETTE_TINT_900_INTERNAL_NAME @"900"
#define MDC_PALETTE_ACCENT_100_INTERNAL_NAME @"A100"
#define MDC_PALETTE_ACCENT_200_INTERNAL_NAME @"A200"
#define MDC_PALETTE_ACCENT_400_INTERNAL_NAME @"A400"
#define MDC_PALETTE_ACCENT_700_INTERNAL_NAME @"A700"

/** Return YES if a string is one of the pre-defined tint/accent names. */
BOOL MDCPaletteIsTintOrAccentName(NSString* _Nonnull name);
