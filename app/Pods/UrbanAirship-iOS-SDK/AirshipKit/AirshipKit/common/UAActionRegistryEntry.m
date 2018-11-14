/* Copyright 2017 Urban Airship and Contributors */

#import "UAActionRegistryEntry+Internal.h"

@interface UAActionRegistryEntry()
@property (nonatomic, strong) NSMutableDictionary *situationOverrides;
@end
@implementation UAActionRegistryEntry
@dynamic names;

- (instancetype)initWithAction:(UAAction *)action predicate:(UAActionPredicate)predicate {
    self = [super init];
    if (self) {
        self.action = action;
        self.actionClass = [action class];
        self.predicate = predicate;
        self.mutableNames = [NSMutableArray array];
        self.situationOverrides = [NSMutableDictionary dictionary];
    }

    return self;
}

- (instancetype)initWithActionClass:(Class)actionClass predicate:(UAActionPredicate)predicate {
    self = [super init];
    if (self) {
        self.actionClass = actionClass;
        self.predicate = predicate;
        self.mutableNames = [NSMutableArray array];
        self.situationOverrides = [NSMutableDictionary dictionary];
    }

    return self;
}

- (UAAction *)action
{
    if (_action == nil)
    {
        _action = [[self.actionClass alloc] init];
    }
    return _action;
}

- (UAAction *)actionForSituation:(UASituation)situation {
    return [self.situationOverrides objectForKey:[NSNumber numberWithInt:situation]] ?: self.action;
}

- (void)addSituationOverride:(UASituation)situation withAction:(UAAction *)action {
    if (action) {
        [self.situationOverrides setObject:action forKey:@(situation)];
    } else {
        [self.situationOverrides removeObjectForKey:@(situation)];
    }
}

+ (instancetype)entryForAction:(UAAction *)action predicate:(UAActionPredicate)predicate {
    return [[self alloc] initWithAction:action predicate:predicate];
}

+ (instancetype)entryForActionClass:(Class)actionClass predicate:(UAActionPredicate)predicate {
    return [[self alloc] initWithActionClass:actionClass predicate:predicate];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"UAActionRegistryEntry names: %@, predicate: %@, action: %@, actionClass:%@",
            self.names, self.predicate, self.action, self.actionClass];
}

- (NSArray *)names {
    return [NSArray arrayWithArray:self.mutableNames];
}

@end
