//
//  JasonNSClassFromString.h
//  Jasonette
//
//  Created by Jasonelle Team on 07-07-19.
//  Copyright © 2019 Jasonette. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * Wrapper methods to NSClassFromString();
 */
@interface JasonNSClassFromString : NSObject

/*!
 * @brief
 * NSClassFromString return nil on some Swift classes.
 * This is a wrapper that tries finding the class regardless.
 *
 * @details
 * If you are using Swift for an Extension then try including the \@objc() annotation.
 *
 \@objc(MySwiftClass)
 * class MySwiftClass {
 * ...
 * }
 *
 * See https://stackoverflow.com/questions/28706602/nsclassfromstring-using-a-swift-file
 * and https://github.com/Jasonette/JASONETTE-iOS/issues/363#event-2459148079
 *
 * @param className
 * @return Class
 */

+ (nullable Class)classFromString:(nonnull NSString *)className;

@end
