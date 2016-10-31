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
typedef BOOL(^APFilterContactsBlock)(APContact * _Nonnull contact);
typedef void(^APLoadContactsBlock)(NSArray <APContact *> * _Nullable contacts, NSError * _Nullable error);
typedef void(^APLoadContactBlock)(APContact * _Nullable contact);
typedef void(^APLoadPhotoBlock)(UIImage * _Nullable photo);
typedef void(^APRequestAccessBlock)(BOOL granted, NSError * _Nullable error);

@interface APAddressBook : NSObject

@property (nonatomic, assign) APContactField fieldsMask;
@property (nullable, nonatomic, copy) APFilterContactsBlock filterBlock;
@property (nullable, nonatomic, strong) NSArray <NSSortDescriptor *> *sortDescriptors;

+ (APAddressBookAccess)access;
- (void)loadContacts:(nonnull APLoadContactsBlock)completionBlock;
- (void)loadContactsOnQueue:(nonnull dispatch_queue_t)queue
                 completion:(nonnull APLoadContactsBlock)completionBlock;
- (void)loadContactByRecordID:(nonnull NSNumber *)recordID
                   completion:(nonnull APLoadContactBlock)completion;
- (void)loadContactByRecordID:(nonnull NSNumber *)recordID
                      onQueue:(nonnull dispatch_queue_t)queue
                   completion:(nonnull APLoadContactBlock)completion;
- (void)loadPhotoByRecordID:(nonnull NSNumber *)recordID
                 completion:(nonnull APLoadPhotoBlock)completion;
- (void)loadPhotoByRecordID:(nonnull NSNumber *)recordID
                    onQueue:(nonnull dispatch_queue_t)queue
                 completion:(nonnull APLoadPhotoBlock)completion;
- (void)startObserveChangesWithCallback:(nonnull void (^)())callback;
- (void)startObserveChangesOnQueue:(nonnull dispatch_queue_t)queue
                          callback:(nonnull void (^)())callback;
- (void)stopObserveChanges;
- (void)requestAccess:(nonnull APRequestAccessBlock)completionBlock;
- (void)requestAccessOnQueue:(nonnull dispatch_queue_t)queue
                  completion:(nonnull APRequestAccessBlock)completionBlock;

@end


@interface APAddressBook (Deprecated)

+ (void)requestAccess:(nonnull APRequestAccessBlock)completionBlock
AP_DEPRECATED("instance method requestAccess:");
+ (void)requestAccessOnQueue:(nonnull dispatch_queue_t)queue
        completion:(nonnull APRequestAccessBlock)completionBlock
AP_DEPRECATED("instance method requestAccessOnQueue:completion:");
- (nullable APContact *)getContactByRecordID:(nonnull NSNumber *)recordID
AP_DEPRECATED("loadContactByRecordID:completion:");

@end