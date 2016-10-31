//
//  APAddressBook.m
//  APAddressBook
//
//  Created by Alexey Belkevich on 1/10/14.
//  Copyright (c) 2014 alterplay. All rights reserved.
//

#import "APAddressBook.h"
#import "APAddressBookAccessRoutine.h"
#import "APAddressBookContactsRoutine.h"
#import "APAddressBookExternalChangeRoutine.h"
#import "APContactListBuilder.h"
#import "APAddressBookRefWrapper.h"
#import "APThread.h"

@interface APAddressBook () <APAddressBookExternalChangeDelegate>
@property (nonatomic, strong) APAddressBookAccessRoutine *access;
@property (nonatomic, strong) APAddressBookContactsRoutine *contacts;
@property (nonatomic, strong) APAddressBookExternalChangeRoutine *externalChange;
@property (nonatomic, strong) APThread *thread;
@property (atomic, copy) void (^externalChangeCallback)();
@property (atomic, strong) dispatch_queue_t externalChangeQueue;
@end

@implementation APAddressBook

#pragma mark - life cycle

- (id)init
{
    self = [super init];
    self.fieldsMask = APContactFieldDefault;
    self.thread = [[APThread alloc] init];
    [self.thread start];
    [self.thread dispatchAsync:^
    {
        APAddressBookRefWrapper *refWrapper = [[APAddressBookRefWrapper alloc] init];
        self.access = [[APAddressBookAccessRoutine alloc] initWithAddressBookRefWrapper:refWrapper];
        if (!refWrapper.error)
        {
            self.contacts = [[APAddressBookContactsRoutine alloc] initWithAddressBookRefWrapper:refWrapper];
            self.externalChange = [[APAddressBookExternalChangeRoutine alloc] initWithAddressBookRefWrapper:refWrapper];
            self.externalChange.delegate = self;
        }
        else
        {
            NSLog(@"APAddressBook initialization error:\n%@", refWrapper.error);
        }
    }];
    return self;
}

- (void)dealloc
{
    [self.thread cancel];
}

#pragma mark - public

+ (APAddressBookAccess)access
{
    return [APAddressBookAccessRoutine accessStatus];
}

- (void)loadContacts:(APLoadContactsBlock)completionBlock
{
    [self loadContactsOnQueue:dispatch_get_main_queue() completion:completionBlock];
}

- (void)loadContactsOnQueue:(dispatch_queue_t)queue completion:(APLoadContactsBlock)completionBlock
{
    APContactField fieldMask = self.fieldsMask;
    APContactListBuilder *listBuilder = [[APContactListBuilder alloc] init];
    listBuilder.filterBlock = self.filterBlock;
    listBuilder.sortDescriptors = self.sortDescriptors;
    [self.thread dispatchAsync:^
    {
        [self.access requestAccessWithCompletion:^(BOOL granted, NSError *error)
        {
            [self.thread dispatchAsync:^
            {
                NSArray *contacts = granted ? [self.contacts allContactsWithContactFieldMask:fieldMask] : nil;
                contacts = [listBuilder contactListWithAllContacts:contacts];
                dispatch_async(queue, ^
                {
                    completionBlock ? completionBlock(contacts, error) : nil;
                });
            }];
        }];
    }];
}

- (void)loadContactByRecordID:(NSNumber *)recordID completion:(APLoadContactBlock)completion
{
    [self loadContactByRecordID:recordID onQueue:dispatch_get_main_queue() completion:completion];
}

- (void)loadContactByRecordID:(NSNumber *)recordID onQueue:(dispatch_queue_t)queue
                   completion:(APLoadContactBlock)completion
{
    [self.thread dispatchAsync:^
    {
        APContact *contact = [self.contacts contactByRecordID:recordID withFieldMask:self.fieldsMask];
        dispatch_async(queue, ^
        {
            completion ? completion(contact) : nil;
        });
    }];
}

- (void)loadPhotoByRecordID:(nonnull NSNumber *)recordID completion:(APLoadPhotoBlock)completion
{
    [self loadPhotoByRecordID:recordID onQueue:dispatch_get_main_queue() completion:completion];
}

- (void)loadPhotoByRecordID:(NSNumber *)recordID onQueue:(dispatch_queue_t)queue
                 completion:(APLoadPhotoBlock)completion
{
    [self.thread dispatchAsync:^
    {
        UIImage *image = [self.contacts imageWithRecordID:recordID];
        dispatch_async(queue, ^
        {
            completion ? completion(image) : nil;
        });
    }];
}

- (void)startObserveChangesWithCallback:(void (^)())callback
{
    [self startObserveChangesOnQueue:dispatch_get_main_queue() callback:callback];
}

- (void)startObserveChangesOnQueue:(dispatch_queue_t)queue callback:(void (^)())callback
{
    self.externalChangeCallback = callback;
    self.externalChangeQueue = queue;
}

- (void)stopObserveChanges
{
    self.externalChangeCallback = nil;
    self.externalChangeQueue = nil;
}

- (void)requestAccess:(nonnull APRequestAccessBlock)completionBlock
{
    [self requestAccessOnQueue:dispatch_get_main_queue() completion:completionBlock];
}

- (void)requestAccessOnQueue:(nonnull dispatch_queue_t)queue
                  completion:(nonnull APRequestAccessBlock)completionBlock
{
    [self.thread dispatchAsync:^
    {
        [self.access requestAccessWithCompletion:^(BOOL granted, NSError *error)
        {
            dispatch_async(queue, ^
            {
                completionBlock ? completionBlock(granted, error) : nil;
            });
        }];
    }];
}

#pragma mark - APAddressBookExternalChangeDelegate

- (void)addressBookDidChange
{
    dispatch_queue_t queue = self.externalChangeQueue ?: dispatch_get_main_queue();
    dispatch_async(queue, ^
    {
        self.externalChangeCallback ? self.externalChangeCallback() : nil;
    });
}

#pragma mark - deprecated

+ (void)requestAccess:(APRequestAccessBlock)completionBlock
{
    [self requestAccessOnQueue:dispatch_get_main_queue() completion:completionBlock];
}

+ (void)requestAccessOnQueue:(dispatch_queue_t)queue completion:(APRequestAccessBlock)completionBlock
{
    APAddressBookRefWrapper *refWrapper = [[APAddressBookRefWrapper alloc] init];
    APAddressBookAccessRoutine *access = [[APAddressBookAccessRoutine alloc] initWithAddressBookRefWrapper:refWrapper];
    [access requestAccessWithCompletion:^(BOOL granted, NSError *error)
    {
        dispatch_async(queue, ^
        {
            completionBlock ? completionBlock(granted, error) : nil;
        });
    }];
}

- (APContact *)getContactByRecordID:(NSNumber *)recordID
{
    APContactField fieldMask = self.fieldsMask;
    __block APContact *contact = nil;
    [self.thread dispatchSync:^
    {
        contact = [self.contacts contactByRecordID:recordID withFieldMask:fieldMask];
    }];
    return contact;
}

@end
