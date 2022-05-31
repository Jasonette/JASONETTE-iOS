//
//  DTReachability.m
//  AutoIngest
//
//  Created by Oliver Drobnik on 29.04.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTReachability.h"

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH

#import <UIKit/UIKit.h>

#import "DTLog.h"

@implementation DTReachabilityInformation


- (instancetype)initWithFlags:(SCNetworkReachabilityFlags)reachabilityFlags
{
	self = [super init];

	if (self)
	{
		_reachabilityFlags = reachabilityFlags;
	}
	return self;
}

- (BOOL)isReachable
{
	return (self.reachabilityFlags & kSCNetworkFlagsReachable) && !(self.reachabilityFlags & kSCNetworkFlagsConnectionRequired);
}

#if	TARGET_OS_IPHONE
- (BOOL)isWWAN {
	return [self isReachable] && self.reachabilityFlags & kSCNetworkReachabilityFlagsIsWWAN;
}
#endif	// TARGET_OS_IPHONE


@end


@implementation DTReachability
{
	NSMutableSet *_observers;
	SCNetworkReachabilityRef _reachability;
	SCNetworkReachabilityFlags _connectionFlags;
	NSString *_hostname;
}


static DTReachability *_sharedInstance;

+ (DTReachability *)defaultReachability
{
	static dispatch_once_t instanceOnceToken;
	
	dispatch_once(&instanceOnceToken, ^{

		_sharedInstance = [[DTReachability alloc] init];
	});
	
	return _sharedInstance;
}

- (instancetype)init
{
	return [self initWithHostname:@"apple.com"];
}

- (instancetype) initWithHostname:(NSString *)hostname
{
	self = [super init];
	
	if (self)
	{
		_observers = [[NSMutableSet alloc] init];
		_hostname = hostname;
		
        #if TARGET_OS_IPHONE && !TARGET_OS_WATCH
			[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
			[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
		#endif
	}
	return self;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
	[self _unregisterNetworkReachability];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	[self _registerNetworkReachability];
}



- (void)dealloc
{
	[self _unregisterNetworkReachability];
}

- (id)addReachabilityObserverWithBlock:(void(^)(DTReachabilityInformation *information))observer
{
	@synchronized(self)
	{
		// copy the block
		DTReachabilityObserverBlock block = [observer copy];
		
		// add it to the observers
		[_observers addObject:block];
		
		[self _registerNetworkReachability];

		// get the current flags if possible
		if (SCNetworkReachabilityGetFlags(_reachability, &_connectionFlags))
		{
			block([[DTReachabilityInformation alloc] initWithFlags:_connectionFlags]);
		}

		return block;
	}
}

- (void)removeReachabilityObserver:(id)observer
{
	@synchronized(self)
	{
		[_observers removeObject:observer];
		
		if (![_observers count])
		{
			// if this was the last we don't need the reachability no longer
			[self _unregisterNetworkReachability];
		}
	}
}

+ (id)addReachabilityObserverWithBlock:(void(^)(DTReachabilityInformation *information))observer
{
	return [[DTReachability defaultReachability] addReachabilityObserverWithBlock:observer];
}

+ (void)removeReachabilityObserver:(id)observer
{
	return [[DTReachability defaultReachability] removeReachabilityObserver:observer];
}

- (void)setHostname:(NSString *)hostname
{
	@synchronized(self)
	{
		if (![hostname isEqualToString:_hostname])
		{
			[self _unregisterNetworkReachability];
			_hostname = hostname;
			[self _registerNetworkReachability];
		}
	}
}

#pragma mark - Internals

- (void)_registerNetworkReachability
{
	// first watcher creates reachability
	if (!_reachability)
	{
		_reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [_hostname UTF8String]);
		if (!_reachability) {
			DTLogError(@"No Reachability can be created for hostname: %@", _hostname);
			return;
		}
		SCNetworkReachabilityContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
	
		if(SCNetworkReachabilitySetCallback(_reachability, DTReachabilityCallback, &context))
		{
			if(!SCNetworkReachabilityScheduleWithRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes))
			{
				DTLogError(@"Error: Could not schedule reachability");
				SCNetworkReachabilitySetCallback(_reachability, NULL, NULL);
			}
		}
	}
}

- (void)_unregisterNetworkReachability {
	if (!_reachability) {
		// No reachability exisits, so there is nothing to unregister
		return;
	}

	SCNetworkReachabilitySetCallback(_reachability, NULL, NULL);
	
	if (SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes))
	{
		DTLogInfo(@"Unscheduled reachability");
	}
	else
	{
		DTLogError(@"Error: Could not unschedule reachability");
	}
	
	_reachability = nil;
}

- (void)_notifyObserversWithFlags:(SCNetworkReachabilityFlags)flags
{
	@synchronized(self)
	{
		for (DTReachabilityObserverBlock block in _observers)
		{
			block([[DTReachabilityInformation alloc] initWithFlags:flags]);
		}
	}
}

static void DTReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
	DTReachability *reachability = (__bridge DTReachability *)info;

	[reachability _notifyObserversWithFlags:flags];
}

@end

#endif
