//
//  APAddressBook.h
//  APAddressBook
//
//  Created by Alexey Belkevich on 1/10/14.
//  Copyright (c) 2014 alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "APTypes.h"

@class APContact;

@interface APAddressBook : NSObject

@property (nonatomic, assign) APContactField fieldsMask;
@property (nullable, nonatomic, copy) BOOL(^filterBlock)(APContact * _Nonnull contact);
@property (nullable, nonatomic, strong) NSArray <NSSortDescriptor *> *sortDescriptors;

+ (APAddressBookAccess)access;
- (void)loadContacts:(nonnull void (^)(NSArray <APContact *> * _Nullable contacts, NSError * _Nullable error))completionBlock;
- (void)loadContactsOnQueue:(nonnull dispatch_queue_t)queue
                 completion:(nonnull void (^)(NSArray <APContact *> * _Nullable contacts, NSError * _Nullable error))completionBlock;
- (void)loadContactByRecordID:(nonnull NSNumber *)recordID
                   completion:(nonnull void (^)(APContact * _Nullable contact))completion;
- (void)loadContactByRecordID:(nonnull NSNumber *)recordID
                      onQueue:(nonnull dispatch_queue_t)queue
                   completion:(nonnull void (^)(APContact * _Nullable contact))completion;
- (void)loadPhotoByRecordID:(nonnull NSNumber *)recordID
                 completion:(nonnull void (^)(UIImage * _Nullable photo))completion;
- (void)loadPhotoByRecordID:(nonnull NSNumber *)recordID
                    onQueue:(nonnull dispatch_queue_t)queue
                 completion:(nonnull void (^)(UIImage * _Nullable photo))completion;
- (void)startObserveChangesWithCallback:(nonnull void (^)(void))callback;
- (void)startObserveChangesOnQueue:(nonnull dispatch_queue_t)queue
                          callback:(nonnull void (^)(void))callback;
- (void)stopObserveChanges;
- (void)requestAccess:(nonnull void (^)(BOOL granted, NSError * _Nullable error))completionBlock;
- (void)requestAccessOnQueue:(nonnull dispatch_queue_t)queue
                  completion:(nonnull void (^)(BOOL granted, NSError * _Nullable error))completionBlock;

@end
