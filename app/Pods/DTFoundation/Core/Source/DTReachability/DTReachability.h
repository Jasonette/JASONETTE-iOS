//
//  DTReachability.h
//  AutoIngest
//
//  Created by Oliver Drobnik on 29.04.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//


#import <Availability.h>
#import <TargetConditionals.h>

#import <Foundation/Foundation.h>

#if !TARGET_OS_WATCH

#import <SystemConfiguration/SystemConfiguration.h>

/**
 Reachability Information object that encapsulates the current `SCNetworkReachabilityFlags` for passing to reachability observers registered on DTReachability.
 */
@interface DTReachabilityInformation : NSObject

/**
 @name Getting Reachability Information
 */

/**
@returns `YES` if the configured host is reachable via the Internet.
*/
- (BOOL)isReachable;

#if	TARGET_OS_IPHONE
/**
 @returns `YES` if the configured host is reachable via a cellular data connection
 */
- (BOOL)isWWAN;
#endif	// TARGET_OS_IPHONE

/**
 The raw reachability flags
 */
@property (nonatomic, readonly) SCNetworkReachabilityFlags reachabilityFlags;

@end


// block type for the reachability observers
typedef void(^DTReachabilityObserverBlock)(DTReachabilityInformation * _Nonnull reachabilityInformation);


/**
 Block-Based Reachability Observation, using the SystemConfiguration.framework. Based largely on Erica Sadun's [UIDevice Reachability Extension](https://github.com/erica/uidevice-extension/blob/master/UIDevice-Reachability.m). Modified to use `SCNetworkReachabilityCreateWithName` instead based on Nick Lockwoods [FXReachability](http://github.com/nicklockwood/FXReachability) because this approach also takes the DNS resolvability into consideration.
 
 A shared instance is provided via +defaultReachability which is configured to check reachability of apple.com. Custom reachability manager instances can be configure to monitor reachability of custom host names.
 */
@interface DTReachability : NSObject


/**
 Returns an initialized DTReachability instance with the default hostname: apple.com

 @returns An initialized DTReachability instance.
 */
- (instancetype _Nonnull)init;

/**
 Returns an initialized DTReachability instance with a given host name
 
 @param hostname The host name to monitor
 @returns An initialized DTReachability instance.
 */
- (instancetype _Nonnull)initWithHostname:(NSString * _Nonnull)hostname;

/**
 Returns a shared DTReachability instance with the default hostname is apple.com. Generally you should use this because each DTReachability instance maintains its own table of observers.
 
 @returns the default DTReachability instance
 */
+ (DTReachability * _Nonnull)defaultReachability;


/**
 Adds a block to observe network reachability. Every time the reachability flags change this block is invoked. Also once right after adding the observer with the current state.
 @warning use -[[DTReachability defaultReachability] addReachabilityObserverWithBlock:]
 @param observer An observation block
 @returns An opaque reference to the observer which you can use to remove it
 */
+ (_Nonnull id)addReachabilityObserverWithBlock:(DTReachabilityObserverBlock _Nonnull )observer __attribute__((deprecated("use -[[DTReachability defaultReachability] addReachabilityObserverWithBlock:]")));


/**
 Removes a reachability observer.
 @warning use -[[DTReachability defaultReachability] removeReachabilityObserver:]
 @param observer The opaque reference to a reachability observer
 */
+ (void)removeReachabilityObserver:(id _Nonnull)observer __attribute__((deprecated("use -[[DTReachability defaultReachability] removeReachabilityObserver:]")));

/**
 
 Adds a block to observe network reachability. Every time the reachability flags change this block is invoked. Also once right after adding the observer with the current state.
 @param observer An observation block
 @returns An opaque reference to the observer which you can use to remove it
 */
- (id _Nonnull)addReachabilityObserverWithBlock:(DTReachabilityObserverBlock _Nonnull)observer;


/**
 Removes a reachability observer block from the receiver.
 @param observer The opaque reference to a reachability observer
 */
- (void)removeReachabilityObserver:(id _Nonnull)observer;


/**
 Changes the hostname that is monitored for the receiver. All registered observer blocks will be called on reachability changes for the new hostname.
 
 @param hostname The new hostname that is monitored
 */
- (void)setHostname:(NSString * _Nonnull) hostname;


@end

#endif
