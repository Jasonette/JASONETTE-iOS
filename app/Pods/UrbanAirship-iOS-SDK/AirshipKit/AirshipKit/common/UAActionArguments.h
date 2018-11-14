/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

/**
 * Represents the possible situations.
 */
typedef NS_ENUM(NSInteger, UASituation) {
    /**
     * Represents a situation in which the action was invoked manually.
     */
    UASituationManualInvocation,

    /**
     * Represents a situation in which the application was launched from a push notification.
     */
    UASituationLaunchedFromPush,

    /**
     * Represents a situation in which a push notification was received in the foreground.
     */
    UASituationForegroundPush,

    /**
     * Represents a situation in which a push notification was received in the background.
     */
    UASituationBackgroundPush,

    /**
     * Represents a situation in which the action was triggered from a
     * web view
     */
    UASituationWebViewInvocation,

    /**
     * Represents a situation in which the action was triggered from a
     * foreground interactive notification button.
     */
    UASituationForegroundInteractiveButton,

    /**
     * Represents a situation in which the action was triggered from a
     * background interactive notification button.
     */
    UASituationBackgroundInteractiveButton,

    /**
     * Represents a situation in which the action was triggered from an
     * automation trigger.
     */
    UASituationAutomation,
};


NS_ASSUME_NONNULL_BEGIN

/**
 * Contains the arguments passed into an action during execution.
 */
@interface UAActionArguments : NSObject

/**
 * Metadata key for the web view. Available when an action is triggered from
 * a web view.
 *
 * @deprecated Deprecated - to be removed in SDK version 9.0
 */
extern NSString * const UAActionMetadataWebViewKey DEPRECATED_MSG_ATTRIBUTE("Deprecated - to be removed in SDK version 9.0");

/**
 * Metadata key for the push notification. Available when an action is triggered
 * from a push notification or user notification action.
 */
extern NSString * const UAActionMetadataPushPayloadKey;

/**
 * Metadata key for the push notification. Available when an action is triggered
 * from a push notification that was presented in the foreground with alert options.
 */
extern NSString * const UAActionMetadataForegroundPresentationKey;

/**
 * Metadata key for the inbox message. Available when an action is triggered from
 * a inbox message.
 */
extern NSString * const UAActionMetadataInboxMessageKey;

/**
 * Metadata key for the user notification action identifier. Available when an
 * action is triggered from a user notification action.
 */
extern NSString * const UAActionMetadataUserNotificationActionIDKey;

/**
 * Metadata key for the user notification action response info. Available when an
 * action is triggered from a user notification action with the behavior
 * `UIUserNotificationActionBehaviorTextInput` (iOS 9 and above).
 */
extern NSString * const UAActionMetadataResponseInfoKey;

/**
 * Metadata key for the name of the action in the registry. Available when an
 * action is triggered by name.
 */
extern NSString * const UAActionMetadataRegisteredName;

///---------------------------------------------------------------------------------------
/// @name Action Arguments Properties
///---------------------------------------------------------------------------------------

/**
 * Situation of the action
 */
@property (nonatomic, assign, readonly) UASituation situation;

/**
 * The value associated with the action
 */
@property (nonatomic, strong, readonly, nullable) id value;

/**
 * The argument's metadata. Metadata provides more information
 * about the environment that the action was triggered from.
 */
@property (nonatomic, copy, readonly, nullable) NSDictionary *metadata;

///---------------------------------------------------------------------------------------
/// @name Action Arguments Factories
///---------------------------------------------------------------------------------------

/**
 * UAActionArguments factory method.
 *
 * @param value The value associated with the arguments.
 * @param situation The situation of the action.
 */
+ (instancetype)argumentsWithValue:(nullable id)value
                     withSituation:(UASituation)situation;


/**
 * UAActionArguments factory method.
 *
 * @param value The value associated with the arguments.
 * @param situation The situation of the action.
 * @param metadata for the action - e.g. webview, payload, etc.
 */
+ (instancetype)argumentsWithValue:(nullable id)value
                     withSituation:(UASituation)situation
                          metadata:(nullable NSDictionary *)metadata;

@end

NS_ASSUME_NONNULL_END
