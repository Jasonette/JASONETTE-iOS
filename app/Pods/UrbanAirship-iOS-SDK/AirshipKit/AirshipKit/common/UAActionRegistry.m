/* Copyright 2017 Urban Airship and Contributors */

#import "UAActionRegistry+Internal.h"
#import "UAActionRegistryEntry+Internal.h"
#import "UAOpenExternalURLAction.h"
#import "UAAddTagsAction.h"
#import "UARemoveTagsAction.h"
#import "UAirship.h"
#import "UAApplicationMetrics.h"
#import "UAAddCustomEventAction.h"
#import "UACancelSchedulesAction.h"
#import "UAScheduleAction.h"
#import "UAFetchDeviceInfoAction.h"
#import "UAEnableFeatureAction.h"

#if !TARGET_OS_TV
#import "UADisplayInboxAction.h"
#import "UAPasteboardAction.h"
#import "UAOverlayInboxMessageAction.h"
#import "UAShareAction.h"
#import "UALandingPageAction.h"
#import "UAChannelCaptureAction.h"
#import "UAWalletAction.h"
#import "UADeepLinkAction.h"

#import "UAShareActionPredicate+Internal.h"
#import "UAOverlayInboxMessageActionPredicate+Internal.h"
#import "UALandingPageActionPredicate+Internal.h"
#endif

#import "UAFetchDeviceInfoActionPredicate+Internal.h"
#import "UAAddCustomEventActionPredicate+Internal.h"
#import "UATagsActionPredicate+Internal.h"

NSString *const defaultsClassKey = @"class";
NSString *const defaultsNameKey = @"name";
NSString *const defaultsAltNameKey = @"altName";
NSString *const defaultsPredicateClassKey = @"predicate";

@implementation UAActionRegistry
@dynamic registeredEntries;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.registeredActionEntries = [[NSMutableDictionary alloc] init];
        self.reservedEntryNames = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)defaultRegistry {
    UAActionRegistry *registry = [[UAActionRegistry alloc] init];
    [registry registerDefaultActions];
    return registry;
}

- (BOOL)registerAction:(UAAction *)action names:(NSArray *)names {
    return [self registerAction:action names:names predicate:nil];
}

- (BOOL)registerAction:(UAAction *)action name:(NSString *)name {
    return [self registerAction:action name:name predicate:nil];
}

- (BOOL)registerActionClass:(Class)actionClass names:(NSArray *)names {
    return [self registerActionClass:actionClass names:names predicate:nil];
}

- (BOOL)registerActionClass:(Class)actionClass name:(NSString *)name {
    return [self registerActionClass:actionClass name:name predicate:nil];
}

- (BOOL)registerAction:(UAAction *)action
                  name:(NSString *)name
             predicate:(UAActionPredicate)predicate {

    if (!name) {
        return NO;
    }

    return [self registerAction:action names:@[name] predicate:predicate];
}

- (BOOL)checkParentClass:(Class)actionClass {

    if ([actionClass isSubclassOfClass:[UAAction class]]) {
        return YES;
    }

    return NO;
}

- (BOOL)registerActionClass:(Class)actionClass
                       name:(NSString *)name
                  predicate:(UAActionPredicate)predicate {
    if (!name) {
        return NO;
    }

    return [self registerActionClass:actionClass names:@[name] predicate:predicate];
}

- (BOOL)registerActionClass:(Class)actionClass
                      names:(NSArray *)names
                  predicate:(UAActionPredicate)predicate {

    if (![self checkParentClass:actionClass]) {
        UA_LWARN(@"Unable to register an action class that isn't a subclass of UAAction.");
        return NO;
    }

    if (!actionClass) {
        UA_LWARN(@"Unable to register a nil action class.");
        return NO;
    }

    UAActionRegistryEntry *entry = [UAActionRegistryEntry entryForActionClass:actionClass
                                                                    predicate:predicate];

    return [self registerEntry:entry names:names];
}

- (BOOL)registerAction:(UAAction *)action
                 names:(NSArray *)names
             predicate:(UAActionPredicate)predicate {

    if (!action) {
        UA_LWARN(@"Unable to register a nil action.");
        return NO;
    }

    UAActionRegistryEntry *entry = [UAActionRegistryEntry entryForAction:action
                                                               predicate:predicate];

    return [self registerEntry:entry names:names];
}

- (BOOL)registerEntry:(UAActionRegistryEntry *)entry
                names:(NSArray *)names {

    if (!names.count) {
        UA_LWARN(@"Unable to register action class. A name must be specified.");
        return NO;
    }

    for (NSString *name in names) {
        if ([self.reservedEntryNames containsObject:name]) {
            UA_LWARN(@"Unable to register entry. %@ is a reserved action.", name);
            return NO;
        }
    }

    for (NSString *name in names) {
        [self removeName:name];
        [entry.mutableNames addObject:name];
        [self.registeredActionEntries setValue:entry forKey:name];
    }

    return YES;
}

- (BOOL)registerReservedAction:(UAAction *)action
                          name:(NSString *)name
                     predicate:(UAActionPredicate)predicate {
    if ([self registerAction:action name:name predicate:predicate]) {
        [self.reservedEntryNames addObject:name];
        return YES;
    }
    return NO;
}

- (BOOL)registerReservedActionClass:(Class)class
                               name:(NSString *)name
                          predicate:(UAActionPredicate)predicate {
    if ([self registerActionClass:class name:name predicate:predicate]) {
        [self.reservedEntryNames addObject:name];
        return YES;
    }
    return NO;
}

- (BOOL)removeName:(NSString *)name {
    if (!name) {
        return YES;
    }

    if ([self.reservedEntryNames containsObject:name]) {
        UA_LWARN(@"Unable to remove name for action. %@ is a reserved action name.", name);
        return NO;
    }

    UAActionRegistryEntry *entry = [self registryEntryWithName:name];
    if (entry) {
        [entry.mutableNames removeObject:name];
        [self.registeredActionEntries removeObjectForKey:name];
    }

    return YES;
}

- (BOOL)removeEntryWithName:(NSString *)name {
    if (!name) {
        return YES;
    }

    if ([self.reservedEntryNames containsObject:name]) {
        UA_LWARN(@"Unable to remove entry. %@ is a reserved action name.", name);
        return NO;
    }

    UAActionRegistryEntry *entry = [self registryEntryWithName:name];

    for (NSString *entryName in entry.mutableNames) {
        if ([self.reservedEntryNames containsObject:entryName]) {
            UA_LWARN(@"Unable to remove entry. %@ is a reserved action.", name);
            return NO;
        }
    }

    for (NSString *entryName in entry.mutableNames) {
        [self.registeredActionEntries removeObjectForKey:entryName];
    }

    return YES;
}

- (BOOL)addName:(NSString *)name forEntryWithName:(NSString *)entryName {
    if (!name) {
        UA_LWARN(@"Unable to add a nil name for entry.");
        return NO;
    }

    if ([self.reservedEntryNames containsObject:entryName]) {
        UA_LWARN(@"Unable to add name to a reserved entry. %@ is a reserved action name.", entryName);
        return NO;
    }

    if ([self.reservedEntryNames containsObject:name]) {
        UA_LWARN(@"Unable to add name for entry. %@ is a reserved action name.", name);
        return NO;
    }

    UAActionRegistryEntry *entry = [self registryEntryWithName:entryName];

    if (entry && name) {
        [self removeName:name];
        [entry.mutableNames addObject:name];
        [self.registeredActionEntries setValue:entry forKey:name];
        return YES;
    }

    return NO;
}

- (UAActionRegistryEntry *)registryEntryWithName:(NSString *)name {
    if (!name) {
        return nil;
    }

    return [self.registeredActionEntries valueForKey:name];
}

- (NSSet *)registeredEntries {
    NSMutableDictionary *entries = [NSMutableDictionary dictionaryWithDictionary:self.registeredActionEntries];
    [entries removeObjectsForKeys:self.reservedEntryNames];
    return [NSSet setWithArray:[entries allValues]];
}

- (BOOL)addSituationOverride:(UASituation)situation
            forEntryWithName:(NSString *)name
                      action:(UAAction *)action {
    if (!name) {
        return NO;
    }

    // Don't allow situation overrides on reserved actions
    if ([self.reservedEntryNames containsObject:name]) {
        UA_LWARN(@"Unable to override situations. %@ is a reserved action name.", name);
        return NO;
    }

    UAActionRegistryEntry *entry = [self registryEntryWithName:name];
    [entry addSituationOverride:situation withAction:action];

    return (entry != nil);
}

- (BOOL)updatePredicate:(UAActionPredicate)predicate forEntryWithName:(NSString *)name {
    if (!name) {
        return NO;
    }

    if ([self.reservedEntryNames containsObject:name]) {
        UA_LWARN(@"Unable to update predicate. %@ is a reserved action name.", name);
        return NO;
    }

    UAActionRegistryEntry *entry = [self registryEntryWithName:name];
    entry.predicate = predicate;
    return (entry != nil);
}

- (BOOL)updateAction:(UAAction *)action forEntryWithName:(NSString *)name {
    if (!name || !action) {
        return NO;
    }

    if ([self.reservedEntryNames containsObject:name]) {
        UA_LWARN(@"Unable to update action. %@ is a reserved action name.", name);
        return NO;
    }

    UAActionRegistryEntry *entry = [self registryEntryWithName:name];
    entry.action = action;
    return (entry != nil);
}

- (BOOL)updateActionClass:(Class)actionClass forEntryWithName:(NSString *)name {
    if (!name || !actionClass) {
        return NO;
    }

    if ([self.reservedEntryNames containsObject:name]) {
        UA_LWARN(@"Unable to update action. %@ is a reserved action name.", name);
        return NO;
    }

    UAActionRegistryEntry *entry = [self registryEntryWithName:name];
    entry.actionClass = actionClass;
    return (entry != nil);
}

- (void)registerDefaultActions {
    NSString *path = [[UAirship resources] pathForResource:@"UADefaultActions" ofType:@"plist"];

    if (!path) {
        return;
    }

    NSArray *defaults = [NSArray arrayWithContentsOfFile:path];

    if (!defaults) {
        return;
    }

    for (NSDictionary *defaultsEntry in defaults) {
        NSMutableArray *names = [NSMutableArray array];
        Class predicateClass;

        if (defaultsEntry[defaultsClassKey] == nil) {
            UA_LERR(@"UADefaultActions.plist must provide a default class string under the key %@", defaultsClassKey);
            break;
        }

        if (defaultsEntry[defaultsNameKey] == nil) {
            UA_LERR(@"UADefaultActions.plist must provide a default name string under the key %@", defaultsNameKey);
            break;
        }

        [names addObject:defaultsEntry[defaultsNameKey]];

        if (defaultsEntry[defaultsAltNameKey]) {
            [names addObject:defaultsEntry[defaultsAltNameKey]];
        }

        Class actionClass = NSClassFromString(defaultsEntry[defaultsClassKey]);

        if (![actionClass class]) {
            UA_LERR(@"Missing action class: %@", defaultsEntry[defaultsClassKey]);
            break;
        }

        id actionObj = [[actionClass alloc] init];

        if (![actionObj isKindOfClass:[UAAction class]]) {
            UA_LERR(@"The action class: %@ must be a subclass of UAAction.", defaultsEntry[defaultsClassKey]);
            break;
        }

        if (defaultsEntry[defaultsPredicateClassKey]) {
            predicateClass = NSClassFromString(defaultsEntry[defaultsPredicateClassKey]);

            if (!predicateClass) {
                UA_LERR(@"Missing predicate class: %@", defaultsEntry[defaultsPredicateClassKey]);
            }
        }

        id<UAActionPredicateProtocol> predicate = [[predicateClass alloc] init];
        BOOL (^predicateBlock)(UAActionArguments *) = nil;

        if (predicate) {
            predicateBlock = ^BOOL(UAActionArguments *args) {
                if ([predicate respondsToSelector:@selector(applyActionArguments:)]) {
                    return [predicate applyActionArguments:args];
                }

                return YES;
            };
        }

        [self registerActionClass:[actionClass class]
                            names:[NSArray arrayWithArray:names]
                        predicate:predicateBlock];
    }
}

@end
