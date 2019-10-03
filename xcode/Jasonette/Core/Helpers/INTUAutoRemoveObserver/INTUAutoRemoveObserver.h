//
//  INTUAutoRemoveObserver.h
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
//
//	The problem with NotificationCenter observers is that you have to remember to remove
//	the observing object when it gets dealloc'ed or your app will crash on the next notification.
//
//	The methods below create a small "remover" object that is associated with the observer object
//	such that when the observer object gets dealloc'ed this object will also get dealloc'ed *and*
//	remove the observations.
//
//	N.B.: This class is designed to remove the observer when the observer is dealloc'ed. If you
//	need to remove the observer before that then you should use the standard methods and be sure
//	to handle the dealloc case yourself.
//
//	Instead of writing:
//
//		// Selector based
//		[[NSNotificationCenter defaultCenter] addObserver:notificationObserver
//												 selector:notificationSelector
//													 name:notificationName
//												   object:notificationSender];
//
//		// Block based
//		[[NSNotificationCenter defaultCenter] addObserverForName:name
//														  object:obj
//														   queue:queue
//													  usingBlock:block];
//
//	you write:
//
//		// Selector based
//		[INTUAutoRemoveObserver addObserver:notificationObserver
//								   selector:notificationSelector
//									   name:notificationName
//									 object:notificationSender];
//
//		// Block based
//		[INTUAutoRemoveObserver addObserver:self
//									forName:name
//									 object:obj
//									  queue:queue
//								 usingBlock:block];
//
//	E.g.:
//
//		// Selector based
//		[INTUAutoRemoveObserver addObserver:self
//								   selector:@selector(myMethod)
//									   name:@"BroadcastNotification"
//									 object:nil];
//
//		// Block based
//		MyObject* __weak weakSelf = self;		// So the block doesn't retain us
//		[INTUAutoRemoveObserver addObserver:self
//									forName:@"BroadcastNotification"
//									 object:nil
//									  queue:[NSOperationQueue mainQueue]
//								 usingBlock:^(NSNotification *note) {
//											 [weakSelf observeMe];
//									 }];

#import <Foundation/Foundation.h>

@interface INTUAutoRemoveObserver : NSObject

// Notification Center observers
+(void)addObserver:(id)notificationObserver selector:(SEL)notificationSelector name:(NSString *)notificationName object:(id)notificationSender;

+(void)addObserver:(id)notificationObserver forName:(NSString *)name object:(id)obj queue:(NSOperationQueue *)queue usingBlock:(void (^)(NSNotification * note))block;

@end
