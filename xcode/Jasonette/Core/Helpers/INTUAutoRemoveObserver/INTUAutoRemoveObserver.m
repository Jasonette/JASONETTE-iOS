//
//  INTUAutoRemoveObserver.m
//
//  Created by Jeff Shulman on 3/18/14.
//	Copyright (c) 2014 Intuit Inc
//
//	Permission is hereby granted, free of charge, to any person obtaining
//	a copy of this software and associated documentation files (the
//	"Software"), to deal in the Software without restriction, including
//	without limitation the rights to use, copy, modify, merge, publish,
//	distribute, sublicense, and/or sell copies of the Software, and to
//	permit persons to whom the Software is furnished to do so, subject to
//	the following conditions:
//
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//	LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//	OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//	WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "INTUAutoRemoveObserver.h"
#import <objc/runtime.h>

@interface INTUAutoRemoveObserver ()

// The observer is "unsafe_unretained" since we don't want a strong reference to change the
// observer refcount and we don't want to be weak since our dealloc will be called after
// the observer has been dealloc'ed itself.
@property (nonatomic, unsafe_unretained) id notificationObserver;

@property (nonatomic, assign) id notificationSender;
@property (nonatomic, copy) NSString* notificationName;

// This is to store a reference to any block created observer
@property (nonatomic, strong) id blockObserver;

@end

@implementation INTUAutoRemoveObserver

+(void)addObserver:(id)notificationObserver selector:(SEL)notificationSelector name:(NSString *)notificationName object:(id)notificationSender
{
	// Create the remover object
	INTUAutoRemoveObserver* remover = [[INTUAutoRemoveObserver alloc] init];
	remover.notificationObserver = notificationObserver;
	remover.notificationName = notificationName;
	remover.notificationSender = notificationSender;
	
	// Keep this object around for the lifetime of the observer
	objc_setAssociatedObject(notificationObserver, (__bridge const void *)(remover), remover, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	// Now register for the notification
	[[NSNotificationCenter defaultCenter] addObserver:notificationObserver
											 selector:notificationSelector
												 name:notificationName
											   object:notificationSender];
}

+(void)addObserver:(id)notificationObserver forName:(NSString *)name object:(id)obj queue:(NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *))block;
{
	// Create the remover object
	INTUAutoRemoveObserver* remover = [[INTUAutoRemoveObserver alloc] init];
	
	id blockObserver = [[NSNotificationCenter defaultCenter] addObserverForName:name
																		 object:obj
																		  queue:queue
																	 usingBlock:block];
	
	// Keep this object around for the lifetime of the notificationObserver object
	objc_setAssociatedObject(notificationObserver, (__bridge const void *)(remover), remover, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	remover.blockObserver = blockObserver;
}

-(void)dealloc
{
	if ( self.blockObserver ) {
		// A block based notification center observer
		[[NSNotificationCenter defaultCenter] removeObserver:self.blockObserver];
	}
	else {
		// A selector based notification center observer
		[[NSNotificationCenter defaultCenter] removeObserver:self.notificationObserver
														name:self.notificationName
													  object:self.notificationSender];
	}
}

@end
