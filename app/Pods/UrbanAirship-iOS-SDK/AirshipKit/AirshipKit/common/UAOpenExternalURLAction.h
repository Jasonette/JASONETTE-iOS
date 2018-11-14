/* Copyright 2017 Urban Airship and Contributors */

#import "UAAction.h"

#define kUAOpenExternalURLActionDefaultRegistryName @"open_external_url_action"
#define kUAOpenExternalURLActionDefaultRegistryAlias @"^u"

/**
 * Represents the possible error conditions
 * when running a `UAOpenExternalURLAction`.
 */
typedef NS_ENUM(NSInteger, UAOpenExternalURLActionErrorCode) {
    /**
     * Indicates that the URL failed to open.
     */
    UAOpenExternalURLActionErrorCodeURLFailedToOpen
};

NS_ASSUME_NONNULL_BEGIN

/**
 * The domain for errors encountered when running a `UAOpenExternalURLAction`.
 */
extern NSString * const UAOpenExternalURLActionErrorDomain;

/**
 * Opens a URL, either in safari or using custom URL schemes. This action is 
 * registered under the names ^u and open_external_url_action.
 *
 * Expected argument values: NSString
 *
 * Valid situations: UASituationForegroundPush, UASituationLaunchedFromPush
 * UASituationWebViewInvocation, UASituationForegroundInteractiveButton,
 * UASituationManualInvocation, and UASituationAutomation
 *
 * Result value: An NSString representation of the input
 *
 * Error: `UAOpenExternalURLActionErrorCodeURLFailedToOpen` if the URL could not be opened
 *
 * Fetch result: UAActionFetchResultNoData
 */
@interface UAOpenExternalURLAction : UAAction

@end

NS_ASSUME_NONNULL_END
