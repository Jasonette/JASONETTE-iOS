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

#import <Foundation/Foundation.h>

@interface NSLocale (MaterialRTL)

/**
 Is the direction of the current locale's default language Left-To-Right?

 @return YES if the language is LTR, NO if the language is any other direction.
 */
+ (BOOL)mdf_isDefaultLanguageLTR;

/**
 Is the direction of the current locale's default language Right-To-Left?

 @return YES if the language is RTL, NO if the language is any other direction.
 */
+ (BOOL)mdf_isDefaultLanguageRTL;

@end

