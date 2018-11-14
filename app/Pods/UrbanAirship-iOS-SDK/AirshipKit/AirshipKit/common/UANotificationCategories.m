/* Copyright 2017 Urban Airship and Contributors */

#import "UANotificationCategories.h"
#import "UAGlobal.h"
#import "NSString+UALocalizationAdditions.h"
#import "UAirship.h"
#import "UANotificationCategory.h"
#import "UANotificationAction.h"
#import "UATextInputNotificationAction.h"

@implementation UANotificationCategories

+ (NSSet *)defaultCategories {
    return [self defaultCategoriesWithRequireAuth:YES];
}

+ (NSSet *)defaultCategoriesWithRequireAuth:(BOOL)requireAuth {
    if (![UAirship resources]) {
        return [NSSet set];
    }

    return [self createCategoriesFromFile:[[UAirship resources] pathForResource:@"UANotificationCategories" ofType:@"plist"]
                              requireAuth:requireAuth];
}

+ (NSSet *)createCategoriesFromFile:(NSString *)path {
    return [self createCategoriesFromFile:path actionDefinitionModBlock:nil];
}

+ (NSSet *)createCategoriesFromFile:(NSString *)path requireAuth:(BOOL)requireAuth {

    return [self createCategoriesFromFile:path actionDefinitionModBlock:^(NSMutableDictionary *actionDefinition) {
        if (![actionDefinition[@"foreground"] boolValue]) {
            actionDefinition[@"authenticationRequired"] = @(requireAuth);
        }
    }];
}

+ (NSSet *)createCategoriesFromFile:(NSString *)path actionDefinitionModBlock:(void (^)(NSMutableDictionary *))actionDefinitionModBlock {

    NSDictionary *categoriesDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];

    NSMutableSet *categories = [NSMutableSet set];

    for (NSString *categoryId in [categoriesDictionary allKeys]) {
        NSArray *actions = [categoriesDictionary valueForKey:categoryId];
        if (!actions.count) {
            continue;
        }

        if (actionDefinitionModBlock) {
            NSMutableArray *mutableActions = [NSMutableArray arrayWithCapacity:actions.count];

            for (id actionDef in actions) {
                NSMutableDictionary *mutableActionDef = [actionDef mutableCopy];
                actionDefinitionModBlock(mutableActionDef);
                [mutableActions addObject:mutableActionDef];
            }

            actions = mutableActions;
        }

        id category = [self createCategory:categoryId actions:actions];
        if (category) {
            [categories addObject:category];
        }
    }

    return categories;
}

+ (UANotificationCategory *)createCategory:(NSString *)categoryId actions:(NSArray *)actionDefinitions {
    NSArray<UANotificationAction *> *actions = [self getActionsFromActionDefinitions:actionDefinitions];
    if (actions) {
        return [UANotificationCategory categoryWithIdentifier:categoryId
                                                      actions:actions
                                            intentIdentifiers:@[]
                                                      options:UANotificationCategoryOptionNone];
    } else {
        return nil;
    }
}

+ (UANotificationCategory * _Nullable)createCategory:(NSString *)categoryId actions:(NSArray *)actionDefinitions hiddenPreviewsBodyPlaceholder:(NSString *)hiddenPreviewsBodyPlaceholder {
    
    NSArray<UANotificationAction *> *actions = [self getActionsFromActionDefinitions:actionDefinitions];
    if (actions) {
        return [UANotificationCategory categoryWithIdentifier:categoryId
                                                      actions:actions
                                            intentIdentifiers:@[]
                                hiddenPreviewsBodyPlaceholder:hiddenPreviewsBodyPlaceholder
                                                      options:UANotificationCategoryOptionNone];
    } else {
        return nil;
    }
}

+(NSArray<UANotificationAction *> *)getActionsFromActionDefinitions:(NSArray *)actionDefinitions {
    NSMutableArray *actions = [NSMutableArray array];

    for (NSDictionary *actionDefinition in actionDefinitions) {
        NSString *title;
        if (actionDefinition[@"title_resource"]) {
            title = [actionDefinition[@"title_resource"] localizedStringWithTable:@"UrbanAirship"
                                                                     defaultValue:actionDefinition[@"title"]];
        } else if (actionDefinition[@"title"]) {
            title = actionDefinition[@"title"];
        }

        NSString *actionId = actionDefinition[@"identifier"];

        if (!title) {
            UA_LERR(@"Error creating action: %@ due to missing required title.",
                    actionId);
            return nil;
        }

        UANotificationActionOptions options = UANotificationActionOptionNone;

        if ([actionDefinition[@"destructive"] boolValue]) {
            options |= UANotificationActionOptionDestructive;
        }

        if ([actionDefinition[@"foreground"] boolValue]) {
            options |= UANotificationActionOptionForeground;
        }

        if ([actionDefinition[@"authenticationRequired"] boolValue]) {
            options |= UANotificationActionOptionAuthenticationRequired;
        }
        
        UANotificationAction *action;
        if ([actionDefinition[@"action_type"] isEqualToString:@"text_input"]) {
            
            NSString *textInputButtonTitle = actionDefinition[@"text_input_button_title"];
            NSString *textInputPlaceholder = actionDefinition[@"text_input_placeholder"];
            
            action = [UATextInputNotificationAction actionWithIdentifier:actionId
                                                                   title:title
                                                    textInputButtonTitle:textInputButtonTitle
                                                    textInputPlaceholder:textInputPlaceholder
                                                                 options:options];
        } else {
            action = [UANotificationAction actionWithIdentifier:actionId
                                                          title:title
                                                        options:options];
        }
        
        [actions addObject:action];
    }
    
    return actions;
}

@end
